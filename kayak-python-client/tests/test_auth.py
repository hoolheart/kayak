"""Tests for authentication (TC-SDK-001 ~ 012, 053 ~ 056)."""

import json
from datetime import datetime, timedelta, timezone

import pytest
from freezegun import freeze_time

from kayak import AuthenticationError, KayakClient, ValidationError


class TestLogin:
    """TC-SDK-001 ~ 004"""

    def test_login_success(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-001: Login — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )

        result = client.login("admin@kayak.local", "Admin123")

        assert result is True
        assert client.auth.access_token is not None
        assert client.auth.refresh_token is not None
        assert client.auth.token_expires_at is not None

    def test_login_invalid_credentials(self, client: KayakClient, httpx_mock):
        """TC-SDK-002: Login — Invalid Credentials"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json={"code": 401, "message": "Invalid email or password"},
            status_code=401,
        )

        with pytest.raises(AuthenticationError):
            client.login("admin@kayak.local", "WrongPassword")

        assert client.auth.access_token is None

    def test_login_server_unavailable(self, client: KayakClient, httpx_mock):
        """TC-SDK-003: Login — Server Unavailable"""
        httpx_mock.add_exception(
            httpx.ConnectError("Connection refused"),
        )

        with pytest.raises(Exception) as exc_info:
            client.login("admin@kayak.local", "Admin123")

        assert client.auth.access_token is None

    def test_login_empty_credentials(self, client: KayakClient):
        """TC-SDK-004: Login — Empty Email or Password"""
        with pytest.raises(ValidationError):
            client.login("", "Admin123")
        with pytest.raises(ValidationError):
            client.login("admin@kayak.local", "")
        with pytest.raises(ValidationError):
            client.login("", "")


class TestLogout:
    """TC-SDK-005 ~ 006"""

    def test_logout_success(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-005: Logout — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/logout",
            json={"code": 200, "message": "success"},
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        client.logout()

        assert client.auth.access_token is None
        assert client.auth.refresh_token is None
        assert client.auth.token_expires_at is None

    def test_logout_without_login(self, client: KayakClient):
        """TC-SDK-006: Logout — Without Prior Login"""
        client.logout()
        assert client.auth.access_token is None


class TestTokenRefresh:
    """TC-SDK-007 ~ 012"""

    @freeze_time("2026-05-11T10:00:00")
    def test_auto_refresh_before_expiry(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-007: Automatic Token Refresh — Triggered Before Expiry"""
        # Login with token expiring in 270s (4.5 min) — below 5 min threshold
        auth_response["data"]["expires_in"] = 270
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        # Mock refresh endpoint
        refresh_response = {
            "code": 200,
            "data": {
                "access_token": "new_access_token",
                "refresh_token": "new_refresh_token",
                "token_type": "Bearer",
                "expires_in": 3600,
            },
        }
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/refresh",
            json=refresh_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 200, "data": []},
            status_code=200,
        )

        client.workbenches.list()

        # Should have called refresh first
        requests = httpx_mock.get_requests()
        assert any("/auth/refresh" in str(r.url) for r in requests)
        assert client.auth.access_token == "new_access_token"

    @freeze_time("2026-05-11T10:00:00")
    def test_no_refresh_when_fresh(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-008: Automatic Token Refresh — Not Triggered When Token Is Fresh"""
        # Login with token expiring in 1800s (30 min)
        auth_response["data"]["expires_in"] = 1800
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 200, "data": []},
            status_code=200,
        )

        client.workbenches.list()

        requests = httpx_mock.get_requests()
        assert not any("/auth/refresh" in str(r.url) for r in requests)

    def test_refresh_on_401(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-009: Automatic Token Refresh — On 401 Response"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        # First workbench request returns 401, second returns 200
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 401, "message": "Unauthorized"},
            status_code=401,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/refresh",
            json={
                "code": 200,
                "data": {
                    "access_token": "new_token",
                    "refresh_token": "new_refresh",
                    "token_type": "Bearer",
                    "expires_in": 3600,
                },
            },
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 200, "data": [{"id": "wb-1", "name": "Test"}]},
            status_code=200,
        )

        result = client.workbenches.list()
        assert len(result) == 1
        assert result[0].id == "wb-1"

    def test_refresh_token_expired(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-010: Automatic Token Refresh — Refresh Token Also Expired"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 401, "message": "Unauthorized"},
            status_code=401,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/refresh",
            json={"code": 401, "message": "Invalid refresh token"},
            status_code=401,
        )

        with pytest.raises(AuthenticationError):
            client.workbenches.list()

    def test_manual_refresh_success(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-011: Manual Token Refresh — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/refresh",
            json={
                "code": 200,
                "data": {
                    "access_token": "new_access",
                    "refresh_token": "new_refresh",
                    "token_type": "Bearer",
                    "expires_in": 3600,
                },
            },
            status_code=200,
        )

        result = client.auth.refresh()
        assert result is True
        assert client.auth.access_token == "new_access"

    def test_manual_refresh_without_login(self, client: KayakClient):
        """TC-SDK-012: Manual Token Refresh — Without Login"""
        with pytest.raises(AuthenticationError):
            client.auth.refresh()


class TestSessionPersistence:
    """TC-SDK-053 ~ 056"""

    def test_save_and_restore_session(self, client: KayakClient, auth_response: dict, httpx_mock, tmp_path):
        """TC-SDK-053: Session Persistence — Save and Restore Tokens"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        client.login("admin@kayak.local", "Admin123")

        session_path = tmp_path / "session.json"
        client.auth.save_session(str(session_path))

        assert session_path.exists()
        data = json.loads(session_path.read_text())
        assert data["access_token"] == client.auth.access_token
        assert data["refresh_token"] == client.auth.refresh_token

        # Create new client and load session
        client2 = KayakClient(base_url="http://localhost:8080")
        client2.auth.load_session(str(session_path))

        assert client2.auth.access_token == client.auth.access_token
        assert client2.auth.is_authenticated()

        # Use restored token
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 200, "data": []},
            status_code=200,
        )
        client2.workbenches.list()

    def test_restore_expired_session(self, client: KayakClient, httpx_mock):
        """TC-SDK-054: Session Persistence — Restore Expired Session"""
        session = {
            "version": 1,
            "base_url": "http://localhost:8080",
            "access_token": "old_access",
            "refresh_token": "old_refresh",
            "token_expires_at": (datetime.now(timezone.utc) - timedelta(hours=1)).isoformat(),
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

        import tempfile
        import os
        with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False) as f:
            json.dump(session, f)
            path = f.name

        try:
            client.auth.load_session(path)

            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/auth/refresh",
                json={
                    "code": 200,
                    "data": {
                        "access_token": "new_access",
                        "refresh_token": "new_refresh",
                        "token_type": "Bearer",
                        "expires_in": 3600,
                    },
                },
                status_code=200,
            )
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/workbenches",
                json={"code": 200, "data": []},
                status_code=200,
            )

            client.workbenches.list()

            requests = httpx_mock.get_requests()
            assert any("/auth/refresh" in str(r.url) for r in requests)
        finally:
            os.unlink(path)

    def test_corrupted_session_file(self, client: KayakClient, tmp_path):
        """TC-SDK-055: Session Persistence — Corrupted Session File"""
        session_path = tmp_path / "bad_session.json"
        session_path.write_text("not json")

        with pytest.raises(ValidationError):
            client.auth.load_session(str(session_path))

    def test_missing_session_file(self, client: KayakClient):
        """TC-SDK-056: Session Persistence — Missing Session File"""
        with pytest.raises(FileNotFoundError):
            client.auth.load_session("/tmp/nonexistent_session_12345.json")


import httpx
