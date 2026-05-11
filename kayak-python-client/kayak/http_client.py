"""HTTP client wrapper with middleware, auth injection, and error mapping."""

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

        if include_auth and self.auth is not None:
            self.auth.ensure_valid_token()
            auth_header = self.auth.get_auth_header()
            if auth_header:
                headers = kwargs.pop("headers", {})
                headers.update(auth_header)
                kwargs["headers"] = headers

        try:
            response = self._client.request(method, url, **kwargs)
        except httpx.ConnectError as e:
            raise ConnectionError(
                f"Failed to connect to {self.base_url}: {e}",
                original_error=e,
            ) from e
        except httpx.ConnectTimeout as e:
            raise ConnectionError(
                f"Connection to {self.base_url} timed out",
                original_error=e,
            ) from e
        except httpx.ReadTimeout as e:
            raise ConnectionError(
                f"Read timeout from {self.base_url}",
                original_error=e,
            ) from e
        except httpx.NetworkError as e:
            raise ConnectionError(
                f"Network error connecting to {self.base_url}: {e}",
                original_error=e,
            ) from e

        # Handle 401 with token refresh retry
        if response.status_code == 401 and include_auth and self.auth is not None:
            try:
                self.auth.refresh()
                auth_header = self.auth.get_auth_header()
                if auth_header:
                    headers = kwargs.pop("headers", {})
                    headers.update(auth_header)
                    kwargs["headers"] = headers
                response = self._client.request(method, url, **kwargs)
            except AuthenticationError:
                # Refresh failed; raise the original 401
                pass

        if response.status_code >= 400:
            raise self._map_http_error(response)

        return response

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
