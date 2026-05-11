"""HTTP client wrapper with middleware, auth injection, and error mapping."""

import random
import time
from typing import TYPE_CHECKING, Any, Optional

import httpx

from kayak.exceptions import (
    AuthenticationError,
    ConnectionError,
    KayakError,
    NotFoundError,
    ServerError,
    ValidationError,
)
from kayak.utils import validate_base_url

if TYPE_CHECKING:
    from kayak.auth import AuthManager


class _RetryMiddleware:
    """Retry middleware with exponential backoff and jitter."""

    MAX_RETRIES: int = 3
    BASE_DELAY: float = 1.0  # seconds
    MAX_DELAY: float = 10.0  # seconds

    def calculate_delay(self, attempt: int) -> float:
        """Exponential backoff with jitter."""
        delay = min(self.BASE_DELAY * (2 ** attempt), self.MAX_DELAY)
        jitter = 0.5 + random.random() * 0.5
        return float(delay * jitter)

    def should_retry(self, error: Exception) -> bool:
        """Determine if an error is retryable."""
        if isinstance(error, ServerError):
            return True
        if isinstance(error, ConnectionError):
            return True
        if isinstance(
            error,
            (
                httpx.ConnectError,
                httpx.ConnectTimeout,
                httpx.ReadTimeout,
                httpx.NetworkError,
            ),
        ):
            return True
        return False


class _HTTPClient:
    """Internal HTTP client wrapping httpx with auth and error handling."""

    API_PREFIX = "/api/v1"

    def __init__(
        self,
        base_url: str,
        timeout: float = 30.0,
        auth: Optional["AuthManager"] = None,
    ) -> None:
        self.base_url = validate_base_url(base_url)
        self.timeout = timeout
        self.auth = auth
        self._client = httpx.Client(timeout=timeout)
        self._retry = _RetryMiddleware()

    def request(
        self,
        method: str,
        path: str,
        *,
        include_auth: bool = True,
        **kwargs: Any,
    ) -> httpx.Response:
        """Make an HTTP request with auth injection and error handling.

        Args:
            method: HTTP method.
            path: API path (will be prefixed with /api/v1).
            include_auth: Whether to include the Authorization header.
            **kwargs: Additional arguments passed to httpx.

        Returns:
            The httpx Response object.

        Raises:
            KayakError: On HTTP error responses.
            ConnectionError: On network failures.
        """
        url = self._build_url(path)
        last_error: Optional[Exception] = None

        for attempt in range(self._retry.MAX_RETRIES + 1):
            if attempt > 0:
                delay = self._retry.calculate_delay(attempt - 1)
                time.sleep(delay)

            # Make a copy of kwargs to avoid mutation across retries
            request_kwargs = dict(kwargs)

            if include_auth and self.auth is not None:
                self.auth.ensure_valid_token()
                auth_header = self.auth.get_auth_header()
                if auth_header:
                    headers = dict(request_kwargs.get("headers", {}))
                    headers.update(auth_header)
                    request_kwargs["headers"] = headers

            try:
                response = self._client.request(method, url, **request_kwargs)
            except (
                httpx.ConnectError,
                httpx.ConnectTimeout,
                httpx.ReadTimeout,
                httpx.NetworkError,
            ) as e:
                if self._retry.should_retry(e) and attempt < self._retry.MAX_RETRIES:
                    last_error = self._map_network_error(e)
                    continue
                raise self._map_network_error(e)

            # Handle 401 with token refresh retry
            if response.status_code == 401 and include_auth and self.auth is not None:
                try:
                    self.auth.refresh(force=True)
                    auth_header = self.auth.get_auth_header()
                    if auth_header:
                        headers = dict(request_kwargs.get("headers", {}))
                        headers.update(auth_header)
                        request_kwargs["headers"] = headers
                    response = self._client.request(method, url, **request_kwargs)
                except AuthenticationError:
                    # Refresh failed; raise the original 401
                    pass

            if response.status_code >= 400:
                error = self._map_http_error(response)
                if self._retry.should_retry(error) and attempt < self._retry.MAX_RETRIES:
                    last_error = error
                    continue
                raise error

            return response

        # All retries exhausted
        if last_error is not None:
            raise last_error
        raise KayakError("Unexpected state: all retries exhausted without error")

    def get(self, path: str, **kwargs: Any) -> httpx.Response:
        """Convenience method for GET requests."""
        return self.request("GET", path, **kwargs)

    def post(self, path: str, **kwargs: Any) -> httpx.Response:
        """Convenience method for POST requests."""
        return self.request("POST", path, **kwargs)

    def close(self) -> None:
        """Close the underlying HTTP client."""
        self._client.close()

    def _build_url(self, path: str) -> str:
        """Build the full URL from base URL, API prefix, and path."""
        if path.startswith("http://") or path.startswith("https://"):
            return path
        # Ensure path starts with /
        if not path.startswith("/"):
            path = "/" + path
        return f"{self.base_url}{self.API_PREFIX}{path}"

    def _map_network_error(self, e: Exception) -> ConnectionError:
        """Map an httpx network exception to the appropriate Kayak exception."""
        if isinstance(e, httpx.ConnectError):
            return ConnectionError(
                f"Failed to connect to {self.base_url}: {e}",
                original_error=e,
            )
        elif isinstance(e, httpx.ConnectTimeout):
            return ConnectionError(
                f"Connection to {self.base_url} timed out",
                original_error=e,
            )
        elif isinstance(e, httpx.ReadTimeout):
            return ConnectionError(
                f"Read timeout from {self.base_url}",
                original_error=e,
            )
        elif isinstance(e, httpx.NetworkError):
            return ConnectionError(
                f"Network error connecting to {self.base_url}: {e}",
                original_error=e,
            )
        else:
            return ConnectionError(
                f"Network error connecting to {self.base_url}: {e}",
                original_error=e,
            )

    def _map_http_error(self, response: httpx.Response) -> KayakError:
        """Map an HTTP error response to the appropriate Kayak exception."""
        status = response.status_code
        try:
            body = response.json()
            message = body.get("message", f"HTTP {status} error")
            details = body.get("data") or body.get("errors") or {}
        except Exception:
            message = response.text or f"HTTP {status} error"
            details = {}

        if status == 401:
            return AuthenticationError(message, details=details)
        elif status == 404:
            return NotFoundError(message=message, details=details)
        elif status == 422:
            return ValidationError(message, details=details)
        elif status >= 500:
            return ServerError(message, status_code=status, details=details)
        else:
            return KayakError(message, status_code=status, details=details)
