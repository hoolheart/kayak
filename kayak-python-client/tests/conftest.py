"""Test fixtures for the Kayak Python SDK."""

import pytest

from kayak import KayakClient


@pytest.fixture
def base_url() -> str:
    return "http://localhost:8080"


@pytest.fixture
def client(base_url: str) -> KayakClient:
    return KayakClient(base_url=base_url)


@pytest.fixture
def auth_response() -> dict:
    return {
        "code": 200,
        "data": {
            "access_token": "eyJhbGciOiJIUzI1NiIs.test_access_token",
            "refresh_token": "dGhpcyBpcyBhIHJlZnJlc2g.test_refresh_token",
            "token_type": "Bearer",
            "expires_in": 3600,
        },
    }


@pytest.fixture
def httpx_mock(httpx_mock):
    """Override httpx_mock to not enforce all registered responses were requested."""
    httpx_mock._options.assert_all_responses_were_requested = False
    yield httpx_mock
