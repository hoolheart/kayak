"""Tests for input validation (TC-SDK-044 ~ 049)."""

import pytest

from kayak import KayakClient, ValidationError


class TestInputValidation:
    """TC-SDK-044 ~ 049"""

    def test_invalid_base_url_missing_scheme(self):
        """TC-SDK-044: Invalid Base URL — Missing Scheme"""
        with pytest.raises(ValidationError, match="scheme"):
            KayakClient(base_url="localhost:8080")

    def test_invalid_base_url_malformed(self):
        """TC-SDK-045: Invalid Base URL — Malformed URL"""
        with pytest.raises(ValidationError, match="scheme"):
            KayakClient(base_url="not a url !!!")

    def test_invalid_uuid(self, client: KayakClient):
        """TC-SDK-046: Invalid UUID Format in Resource APIs"""
        with pytest.raises(ValidationError):
            client.experiments.get("")
        with pytest.raises(ValidationError):
            client.devices.get("")
        with pytest.raises(ValidationError):
            client.data.download("")

    def test_invalid_time_range(self, client: KayakClient):
        """TC-SDK-047: Invalid Time Range — End Before Start"""
        with pytest.raises(ValidationError, match="start_time must be before"):
            client.data.download(
                "exp-123",
                start_time="2026-05-02T00:00:00Z",
                end_time="2026-05-01T00:00:00Z",
            )

    def test_invalid_email(self, client: KayakClient):
        """TC-SDK-048: Invalid Email Format in Login"""
        with pytest.raises(ValidationError, match="Invalid email"):
            client.login("not-an-email", "password123")

    def test_unexpected_kwargs(self, client: KayakClient):
        """TC-SDK-049: Extra / Unexpected Keyword Arguments"""
        with pytest.raises(TypeError):
            client.workbenches.list(unknown_param="value")
