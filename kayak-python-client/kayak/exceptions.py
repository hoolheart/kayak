"""Exception hierarchy for the Kayak Python SDK."""

from typing import Any, Optional


class KayakError(Exception):
    """Base exception for all Kayak SDK errors."""

    def __init__(
        self,
        message: str,
        status_code: Optional[int] = None,
        details: Optional[dict] = None,
        original_error: Optional[Exception] = None,
    ) -> None:
        super().__init__(message)
        self.message = message
        self.status_code = status_code
        self.details = details or {}
        self.original_error = original_error

    def __str__(self) -> str:
        parts = [self.message]
        if self.status_code:
            parts.append(f"(HTTP {self.status_code})")
        if self.details:
            parts.append(f"Details: {self.details}")
        return " ".join(parts)

    def __repr__(self) -> str:
        return (
            f"{self.__class__.__name__}("
            f"message={self.message!r}, status_code={self.status_code}"
            f")"
        )


class AuthenticationError(KayakError):
    """Raised when authentication fails or token is invalid/expired."""

    def __init__(self, message: str = "Authentication failed", **kwargs: Any):
        super().__init__(message, status_code=401, **kwargs)


class NotFoundError(KayakError):
    """Raised when a requested resource is not found (HTTP 404)."""

    def __init__(
        self, resource_type: str = "Resource", resource_id: str = "", **kwargs: Any
    ):
        message = kwargs.pop("message", None)
        if message is None:
            message = f"{resource_type} not found"
            if resource_id:
                message += f": '{resource_id}'"
        super().__init__(message, status_code=404, **kwargs)


class ServerError(KayakError):
    """Raised when the server returns a 5xx error."""

    def __init__(self, message: str = "Server error", **kwargs: Any):
        kwargs.setdefault("status_code", 500)
        super().__init__(message, **kwargs)


class ConnectionError(KayakError):
    """Raised when a network-level connection fails."""

    def __init__(self, message: str = "Connection failed", **kwargs: Any):
        super().__init__(message, **kwargs)


class ValidationError(KayakError):
    """Raised when input validation fails or server returns 422."""

    def __init__(self, message: str = "Validation failed", **kwargs: Any):
        super().__init__(message, status_code=kwargs.get("status_code", 422), **kwargs)
