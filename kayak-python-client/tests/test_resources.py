"""Tests for resource APIs (TC-SDK-017 ~ 026)."""

import pytest

from kayak import AuthenticationError, KayakClient


class TestWorkbenches:
    """TC-SDK-017 ~ 018"""

    def test_list_workbenches(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-017: List Workbenches — Success"""
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
                    {"id": "wb-1", "name": "Workbench A", "description": "Test bench"},
                    {"id": "wb-2", "name": "Workbench B", "description": None},
                ],
            },
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        workbenches = client.workbenches.list()

        assert len(workbenches) == 2
        assert workbenches[0].id == "wb-1"
        assert workbenches[0].name == "Workbench A"

    def test_list_workbenches_with_filter(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-018: List Workbenches — With Scope / Team Filter"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches?scope=team&team_id=team-123",
            json={"code": 200, "data": [{"id": "wb-1", "name": "Team Bench"}]},
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        workbenches = client.workbenches.list(scope="team", team_id="team-123")

        assert len(workbenches) == 1
        assert workbenches[0].name == "Team Bench"


class TestDevices:
    """TC-SDK-019 ~ 020"""

    def test_list_devices(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-019: List Devices — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/devices",
            json={
                "code": 200,
                "data": [
                    {"id": "dev-1", "name": "Device 1", "protocol_type": "virtual"},
                ],
            },
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        devices = client.devices.list()

        assert len(devices) == 1
        assert devices[0].id == "dev-1"

    def test_list_devices_per_workbench(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-020: List Devices — Per Workbench"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/devices?workbench_id=wb-1",
            json={"code": 200, "data": [{"id": "dev-1", "name": "Device 1"}]},
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        devices = client.devices.list(workbench_id="wb-1")

        assert len(devices) == 1


class TestMethods:
    """TC-SDK-021"""

    def test_list_methods(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-021: List Methods — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/methods",
            json={
                "code": 200,
                "data": [
                    {"id": "m-1", "name": "Method 1"},
                ],
            },
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        methods = client.methods.list()

        assert len(methods) == 1
        assert methods[0].id == "m-1"


class TestExperiments:
    """TC-SDK-022 ~ 025"""

    def test_list_experiments(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-022: List Experiments — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments",
            json={
                "code": 200,
                "data": [
                    {"id": "exp-1", "name": "Exp 1", "status": "completed"},
                ],
            },
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        experiments = client.experiments.list()

        assert len(experiments) == 1
        assert experiments[0].status == "completed"

    def test_list_experiments_with_status(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-023: List Experiments — With Status Filter"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments?status=running",
            json={"code": 200, "data": [{"id": "exp-2", "name": "Running Exp", "status": "running"}]},
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        experiments = client.experiments.list(status="running")

        assert len(experiments) == 1
        assert experiments[0].status == "running"

    def test_get_experiment(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-024: Get Experiment Details — Success"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abc",
            json={
                "code": 200,
                "data": {
                    "id": "12345678-1234-1234-1234-123456789abc",
                    "name": "Temperature Test",
                    "status": "completed",
                    "workbench_id": "wb-1",
                    "method_id": "method-1",
                    "created_at": "2026-05-01T00:00:00Z",
                    "updated_at": "2026-05-01T01:00:00Z",
                },
            },
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        exp = client.experiments.get("12345678-1234-1234-1234-123456789abc")

        assert exp.id == "12345678-1234-1234-1234-123456789abc"
        assert exp.name == "Temperature Test"

    def test_get_experiment_not_found(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-025: Get Experiment Details — Not Found"""
        from kayak import NotFoundError

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/00000000-0000-0000-0000-000000000000",
            json={"code": 404, "message": "Not found"},
            status_code=404,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(NotFoundError):
            client.experiments.get("00000000-0000-0000-0000-000000000000")


class TestUnauthenticated:
    """TC-SDK-026"""

    def test_unauthenticated_request(self, client: KayakClient, httpx_mock):
        """TC-SDK-026: List Resources — Unauthenticated Request"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/workbenches",
            json={"code": 401, "message": "Unauthorized"},
            status_code=401,
        )

        with pytest.raises(AuthenticationError):
            client.workbenches.list()
