"""Tests for error handling (TC-SDK-038 ~ 043)."""

from unittest.mock import patch

import httpx
import pytest

from kayak import (
    AuthenticationError,
    ConnectionError,
    KayakError,
    KayakClient,
    NotFoundError,
    ServerError,
    ValidationError,
)


class TestErrorHandling:
    """TC-SDK-038 ~ 043"""

    def test_401_raises_authentication_error(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-038: AuthenticationError — 401 on Any API Call"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/refresh",
            json={"code": 401, "message": "Invalid refresh token"},
            status_code=401,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 401, "message": "Unauthorized"},
            status_code=401,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(AuthenticationError) as exc_info:
            client.workbenches.list()

        assert exc_info.value.status_code == 401

    def test_404_raises_not_found(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-039: NotFoundError — 404 on Any API Call"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/devices/00000000-0000-0000-0000-000000000000",
            json={"code": 404, "message": "Not found"},
            status_code=404,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(NotFoundError) as exc_info:
            client.devices.get("00000000-0000-0000-0000-000000000000")

        assert exc_info.value.status_code == 404

    @patch("kayak.http_client.time.sleep")
    def test_5xx_raises_server_error(self, mock_sleep, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-040: ServerError — 5xx Responses"""
        for _ in range(3):
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/auth/login",
                json=auth_response,
                status_code=200,
            )

        for status in [500, 502, 503]:
            for _ in range(4):
                httpx_mock.add_response(
                    url="http://localhost:8080/api/v1/experiments",
                    json={"code": status, "message": "Server error"},
                    status_code=status,
                )

            client.login("admin@kayak.local", "Admin123")
            with pytest.raises(ServerError) as exc_info:
                client.experiments.list()

            assert exc_info.value.status_code == status

    @patch("kayak.http_client.time.sleep")
    def test_network_error_raises_connection_error(self, mock_sleep, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-041: ConnectionError — Network Failure"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")

        for exc in [
            httpx.ConnectTimeout("timeout"),
            httpx.ReadTimeout("read timeout"),
            httpx.NetworkError("network"),
        ]:
            for _ in range(4):
                httpx_mock.add_exception(exc)

            with pytest.raises(ConnectionError) as exc_info:
                client.workbenches.list()

            assert exc_info.value.original_error is not None

    def test_422_raises_validation_error(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-042: ValidationError — 422 Response"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments?status=invalid",
            json={"code": 422, "message": "Invalid status"},
            status_code=422,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(ValidationError) as exc_info:
            client.experiments.list(status="invalid")

        assert exc_info.value.status_code == 422

    def test_unknown_4xx_raises_base_kayak_error(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-043: Unknown 4xx Error — Fallback to KayakError"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abc/data/download",
            json={"code": 409, "message": "Conflict"},
            status_code=409,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(KayakError) as exc_info:
            client.data.download("12345678-1234-1234-1234-123456789abc")

        assert exc_info.value.status_code == 409
        assert type(exc_info.value) is KayakError
