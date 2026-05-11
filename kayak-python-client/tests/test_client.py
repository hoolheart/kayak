"""Tests for client and context manager (TC-SDK-013 ~ 016)."""

import pytest

from kayak import KayakClient


class TestContextManager:
    """TC-SDK-013 ~ 016"""

    def test_context_manager_entry_exit(self):
        """TC-SDK-013: Context Manager — Successful Entry and Exit"""
        with KayakClient(base_url="http://localhost:8080") as client:
            assert client.base_url == "http://localhost:8080"
            assert isinstance(client, KayakClient)

    def test_context_manager_auto_logout(self, auth_response, httpx_mock):
        """TC-SDK-014: Context Manager — Auto-Logout on Exit When Logged In"""
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

        with KayakClient(base_url="http://localhost:8080") as client:
            client.login("admin@kayak.local", "Admin123")
            assert client.auth.is_authenticated()

        # After exit, tokens should be cleared
        assert not client.auth.is_authenticated()

    def test_context_manager_exception_propagation(self):
        """TC-SDK-015: Context Manager — Exception Inside Block Does Not Suppress Error"""
        client_ref = None
        with pytest.raises(ValueError, match="test error"):
            with KayakClient(base_url="http://localhost:8080") as client:
                client_ref = client
                raise ValueError("test error")

        assert client_ref is not None

    def test_context_manager_combined_workflow(self, auth_response, httpx_mock):
        """TC-SDK-016: Context Manager — Combined Login, API Call, and Logout"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={
                "code": 200,
                "data": [
                    {"id": "wb-1", "name": "Workbench A"},
                    {"id": "wb-2", "name": "Workbench B"},
                ],
            },
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/logout",
            json={"code": 200, "message": "success"},
            status_code=200,
        )

        with KayakClient(base_url="http://localhost:8080") as client:
            client.login("admin@kayak.local", "Admin123")
            workbenches = client.workbenches.list()

        assert len(workbenches) == 2
        assert workbenches[0].id == "wb-1"
        assert workbenches[1].id == "wb-2"
