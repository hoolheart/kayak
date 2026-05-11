"""Tests for concurrent usage (TC-SDK-050 ~ 052)."""

import threading
import time
from concurrent.futures import ThreadPoolExecutor

import pytest

from kayak import KayakClient


class TestConcurrentUsage:
    """TC-SDK-050 ~ 052"""

    def test_concurrent_api_calls(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-050: Concurrent API Calls from Multiple Threads"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        # Register multiple responses for concurrent requests
        for _ in range(3):
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/workbenches",
                json={"code": 200, "data": [{"id": "wb-1", "name": "WB1"}]},
                status_code=200,
            )
        for _ in range(2):
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/experiments",
                json={"code": 200, "data": [{"id": "exp-1", "name": "Exp1"}]},
                status_code=200,
            )

        client.login("admin@kayak.local", "Admin123")

        results = []
        errors = []

        def call_api(fn):
            try:
                results.append(fn())
            except Exception as e:
                errors.append(e)

        threads = [
            threading.Thread(target=call_api, args=(client.workbenches.list,)),
            threading.Thread(target=call_api, args=(client.experiments.list,)),
            threading.Thread(target=call_api, args=(client.workbenches.list,)),
            threading.Thread(target=call_api, args=(client.experiments.list,)),
            threading.Thread(target=call_api, args=(client.workbenches.list,)),
        ]

        for t in threads:
            t.start()
        for t in threads:
            t.join()

        assert len(errors) == 0
        assert len(results) == 5

    def test_token_refresh_during_concurrent(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-051: Token Refresh During Concurrent Requests"""
        from freezegun import freeze_time

        with freeze_time("2026-05-11T10:00:00"):
            # Token expires in 3 min (below threshold)
            auth_response["data"]["expires_in"] = 180
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
                    "access_token": "new_token",
                    "refresh_token": "new_refresh",
                    "token_type": "Bearer",
                    "expires_in": 3600,
                },
            },
            status_code=200,
        )
        for _ in range(3):
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/workbenches",
                json={"code": 200, "data": [{"id": "wb-1", "name": "WB1"}]},
                status_code=200,
            )

        with freeze_time("2026-05-11T10:03:00"):
            results = []
            errors = []

            def call_api():
                try:
                    results.append(client.workbenches.list())
                except Exception as e:
                    errors.append(e)

            threads = [
                threading.Thread(target=call_api),
                threading.Thread(target=call_api),
                threading.Thread(target=call_api),
            ]

            for t in threads:
                t.start()
            for t in threads:
                t.join()

            assert len(errors) == 0
            assert len(results) == 3

            # Should only have one refresh request
            refresh_count = sum(
                1 for r in httpx_mock.get_requests()
                if "/auth/refresh" in str(r.url)
            )
            assert refresh_count == 1

    def test_concurrent_login(self, client: KayakClient, auth_response, httpx_mock):
        """TC-SDK-052: Concurrent Login Attempts"""
        for _ in range(2):
            httpx_mock.add_response(
                url="http://localhost:8080/api/v1/auth/login",
                json=auth_response,
                status_code=200,
            )

        results = []
        errors = []

        def do_login():
            try:
                results.append(client.login("admin@kayak.local", "Admin123"))
            except Exception as e:
                errors.append(e)

        threads = [
            threading.Thread(target=do_login),
            threading.Thread(target=do_login),
        ]

        for t in threads:
            t.start()
        for t in threads:
            t.join()

        # At least one should succeed
        assert any(results)
        assert len(errors) == 0
        assert client.auth.is_authenticated()
