"""Authentication manager for the Kayak Python SDK."""

import json
import threading
from datetime import datetime, timedelta, timezone
from typing import TYPE_CHECKING, Optional

from kayak.exceptions import AuthenticationError, ValidationError
from kayak.models import TokenResponse
from kayak.utils import validate_email, validate_password

if TYPE_CHECKING:
    from kayak.http_client import _HTTPClient


# Refresh threshold: 5 minutes before expiry
_REFRESH_THRESHOLD_SECONDS = 300


class AuthManager:
    """Manages authentication tokens with thread-safe storage and auto-refresh."""

    def __init__(self, http_client: "_HTTPClient") -> None:
        self._http = http_client
        self._state_lock = threading.RLock()
        self._refresh_lock = threading.Lock()
        self.access_token: Optional[str] = None
        self.refresh_token: Optional[str] = None
        self.token_expires_at: Optional[datetime] = None

    def is_authenticated(self) -> bool:
        """Return True if the client currently has an access token."""
        with self._state_lock:
            return self.access_token is not None

    def login(self, email: str, password: str) -> bool:
        """Authenticate with email and password.

        Args:
            email: User email address.
            password: User password.

        Returns:
            True on success.

        Raises:
            ValidationError: If email or password is empty/invalid.
            AuthenticationError: If credentials are rejected by the server.
            ConnectionError: If the network request fails.
        """
        validate_email(email)
        validate_password(password)

        try:
            response = self._http.request(
                "POST",
                "/auth/login",
                json={"email": email, "password": password},
                include_auth=False,
            )
        except Exception:
            raise

        token_response = TokenResponse(**response.json()["data"])
        self._update_tokens(
            token_response.access_token,
            token_response.refresh_token,
            token_response.expires_in,
        )
        return True

    def logout(self) -> None:
        """Log out and clear all token state.

        Calls the backend logout endpoint if authenticated, then clears tokens.
        """
        with self._state_lock:
            has_token = self.access_token is not None

        if has_token:
            try:
                self._http.request("POST", "/auth/logout")
            except Exception:
                # Ignore errors from logout endpoint
                pass

        with self._state_lock:
            self._clear_tokens()

    def refresh(self) -> bool:
        """Manually refresh the access token using the refresh token.

        Returns:
            True on success.

        Raises:
            AuthenticationError: If no refresh token is available or refresh fails.
        """
        with self._refresh_lock:
            with self._state_lock:
                refresh_token = self.refresh_token
                if not refresh_token:
                    raise AuthenticationError("No refresh token available")

            response = self._http.request(
                "POST",
                "/auth/refresh",
                json={"refresh_token": refresh_token},
                include_auth=False,
            )

            token_response = TokenResponse(**response.json()["data"])
            with self._state_lock:
                self._update_tokens(
                    token_response.access_token,
                    token_response.refresh_token,
                    token_response.expires_in,
                )
        return True

    def ensure_valid_token(self) -> None:
        """Ensure the access token is valid, refreshing if necessary.

        Raises:
            AuthenticationError: If the token cannot be refreshed.
        """
        with self._state_lock:
            if not self.access_token:
                raise AuthenticationError("Not authenticated")
            should_refresh = self._should_refresh()

        if should_refresh:
            self.refresh()

    def get_auth_header(self) -> Optional[dict[str, str]]:
        """Return the Authorization header dict if authenticated."""
        with self._state_lock:
            if self.access_token:
                return {"Authorization": f"Bearer {self.access_token}"}
            return None

    def save_session(self, path: str) -> None:
        """Save current session to a JSON file.

        Args:
            path: File path to save the session.

        Raises:
            AuthenticationError: If not currently authenticated.
        """
        with self._state_lock:
            if not self.is_authenticated():
                raise AuthenticationError("Cannot save session: not authenticated")

            session = {
                "version": 1,
                "base_url": self._http.base_url,
                "access_token": self.access_token,
                "refresh_token": self.refresh_token,
                "token_expires_at": (
                    self.token_expires_at.isoformat()
                    if self.token_expires_at
                    else None
                ),
                "created_at": datetime.now(timezone.utc).isoformat(),
            }

        with open(path, "w") as f:
            json.dump(session, f, indent=2)

    def load_session(self, path: str) -> None:
        """Restore session from a JSON file.

        Args:
            path: File path to load the session from.

        Raises:
            FileNotFoundError: If the session file does not exist.
            ValidationError: If the session file is corrupted or invalid.
        """
        try:
            with open(path, "r") as f:
                session = json.load(f)
        except json.JSONDecodeError as e:
            raise ValidationError(f"Invalid session file format: {e}") from e

        if session.get("version") != 1:
            raise ValidationError(
                f"Unsupported session version: {session.get('version')}"
            )

        with self._state_lock:
            self.access_token = session.get("access_token")
            self.refresh_token = session.get("refresh_token")
            expires_at = session.get("token_expires_at")
            if expires_at:
                self.token_expires_at = datetime.fromisoformat(expires_at)

    def _update_tokens(self, access: str, refresh: str, expires_in: int) -> None:
        """Update token state (must be called with _state_lock held)."""
        self.access_token = access
        self.refresh_token = refresh
        self.token_expires_at = datetime.now(timezone.utc) + timedelta(
            seconds=expires_in
        )

    def _clear_tokens(self) -> None:
        """Clear all token state (must be called with _state_lock held)."""
        self.access_token = None
        self.refresh_token = None
        self.token_expires_at = None

    def _should_refresh(self) -> bool:
        """Determine if the token should be refreshed.

        Returns True if the token expiry is known and the current time is
        within REFRESH_THRESHOLD_SECONDS of expiry.
        """
        if self.token_expires_at is None:
            return False
        now = datetime.now(timezone.utc)
        refresh_due = self.token_expires_at - timedelta(
            seconds=_REFRESH_THRESHOLD_SECONDS
        )
        return now >= refresh_due
