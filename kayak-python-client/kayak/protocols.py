"""Protocol classes for structural subtyping."""

from typing import Optional, Protocol, runtime_checkable

import httpx


@runtime_checkable
class _Middleware(Protocol):
    """Protocol for HTTP middleware."""

    def process_request(self, method: str, url: str, kwargs: dict) -> None:
        """Modify request before sending."""
        ...

    def process_response(self, response: httpx.Response) -> None:
        """Process response after receiving."""
        ...


@runtime_checkable
class Authenticator(Protocol):
    """Protocol for authentication providers."""

    def is_authenticated(self) -> bool:
        """Return True if authenticated."""
        ...

    def get_auth_header(self) -> Optional[dict[str, str]]:
        """Return the Authorization header dict if authenticated."""
        ...

    def ensure_valid_token(self) -> None:
        """Ensure the access token is valid, refreshing if necessary."""
        ...
