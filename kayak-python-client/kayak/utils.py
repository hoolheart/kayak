"""Validation utilities and URL helpers for the Kayak SDK."""

import re
import urllib.parse
from datetime import datetime, timezone
from typing import Optional

from kayak.exceptions import ValidationError

# Email regex (simplified but practical)
_EMAIL_RE = re.compile(
    r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
)

# UUID regex (accepts standard UUID format)
_UUID_RE = re.compile(
    r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$"
)


def validate_base_url(url: str) -> str:
    """Validate and normalize a base URL.

    Args:
        url: The base URL to validate.

    Returns:
        The normalized URL (trailing slash stripped).

    Raises:
        ValidationError: If the URL is missing a scheme or is malformed.
    """
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme not in ("http", "https"):
        raise ValidationError(
            f"Base URL must include scheme (http:// or https://): {url}"
        )
    if not parsed.netloc:
        raise ValidationError(f"Invalid base URL: {url}")
    return url.rstrip("/")


def validate_email(email: str) -> None:
    """Validate an email address format.

    Args:
        email: The email address to validate.

    Raises:
        ValidationError: If the email is empty or malformed.
    """
    if not email or not email.strip():
        raise ValidationError("Email must not be empty")
    if not _EMAIL_RE.match(email):
        raise ValidationError(f"Invalid email format: {email}")


def validate_password(password: str) -> None:
    """Validate a password.

    Args:
        password: The password to validate.

    Raises:
        ValidationError: If the password is empty.
    """
    if not password or not password.strip():
        raise ValidationError("Password must not be empty")


def validate_uuid(value: str, field_name: str = "id") -> None:
    """Validate an identifier string.

    Args:
        value: The identifier string to validate.
        field_name: Name of the field for error messages.

    Raises:
        ValidationError: If the value is empty or not a valid UUID format.
    """
    if not value or not value.strip():
        raise ValidationError(f"{field_name} must not be empty")
    if not _UUID_RE.match(value):
        raise ValidationError(
            f"Invalid UUID format for {field_name}: {value}"
        )


def validate_time_range(start_time: str, end_time: str) -> None:
    """Validate a time range.

    Args:
        start_time: ISO 8601 start time string.
        end_time: ISO 8601 end time string.

    Raises:
        ValidationError: If start_time is after end_time.
    """
    start_dt = _parse_iso8601(start_time)
    end_dt = _parse_iso8601(end_time)
    if start_dt > end_dt:
        raise ValidationError("start_time must be before end_time")


def _parse_iso8601(value: str) -> datetime:
    """Parse an ISO 8601 datetime string.

    Handles both 'Z' suffix and '+00:00' offset.
    """
    v = value.replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(v)
    except ValueError as e:
        raise ValidationError(f"Invalid ISO 8601 datetime: {value}") from e
