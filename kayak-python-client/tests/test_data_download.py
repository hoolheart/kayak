"""Tests for data download (TC-SDK-027 ~ 031)."""

import io

import h5py
import pytest

from kayak import KayakClient, NotFoundError
from kayak.exceptions import ServerError


class TestDataDownload:
    """TC-SDK-027 ~ 031"""

    def _create_hdf5_bytes(self) -> bytes:
        """Create a simple HDF5 file in memory."""
        bio = io.BytesIO()
        with h5py.File(bio, "w") as f:
            raw = f.create_group("raw_data")
            device = raw.create_group("device-1")
            device.create_dataset("temperature", data=[[1.0, 25.3], [2.0, 25.4]])
        return bio.getvalue()

    def test_download_hdf5(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-027: Download Experiment Data — HDF5 File Integrity"""
        hdf5_bytes = self._create_hdf5_bytes()

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abc/data/download",
            content=hdf5_bytes,
            status_code=200,
            headers={"Content-Type": "application/octet-stream"},
        )

        client.login("admin@kayak.local", "Admin123")
        data = client.data.download("12345678-1234-1234-1234-123456789abc")

        assert data.experiment_id == "12345678-1234-1234-1234-123456789abc"
        points = data.list_points()
        assert "device-1/temperature" in points

    def test_download_with_time_range(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-028: Download Experiment Data — With Time Range Filter"""
        hdf5_bytes = self._create_hdf5_bytes()

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url=(
                "http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abc/data/download"
                "?start_time=2026-05-01T00%3A00%3A00Z&end_time=2026-05-01T23%3A59%3A59Z"
            ),
            content=hdf5_bytes,
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        data = client.data.download(
            "12345678-1234-1234-1234-123456789abc",
            start_time="2026-05-01T00:00:00Z",
            end_time="2026-05-01T23:59:59Z",
        )

        assert data.experiment_id == "12345678-1234-1234-1234-123456789abc"

    def test_download_save(self, client: KayakClient, auth_response: dict, httpx_mock, tmp_path):
        """TC-SDK-029: Download Experiment Data — Save to Local Path"""
        hdf5_bytes = self._create_hdf5_bytes()

        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abc/data/download",
            content=hdf5_bytes,
            status_code=200,
        )

        client.login("admin@kayak.local", "Admin123")
        data = client.data.download("12345678-1234-1234-1234-123456789abc")

        output_path = tmp_path / "exp-123.h5"
        data.save(str(output_path))

        assert output_path.exists()
        with h5py.File(str(output_path), "r") as f:
            assert "raw_data" in f

    def test_download_not_found(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-030: Download Experiment Data — Experiment Not Found"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/00000000-0000-0000-0000-000000000000/data/download",
            json={"code": 404, "message": "Not found"},
            status_code=404,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(NotFoundError):
            client.data.download("00000000-0000-0000-0000-000000000000")

    def test_download_running_experiment(self, client: KayakClient, auth_response: dict, httpx_mock):
        """TC-SDK-031: Download Experiment Data — Experiment Still Running"""
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/auth/login",
            json=auth_response,
            status_code=200,
        )
        httpx_mock.add_response(
            url="http://localhost:8080/api/v1/experiments/12345678-1234-1234-1234-123456789abd/data/download",
            json={"code": 409, "message": "Experiment is still running"},
            status_code=409,
        )

        client.login("admin@kayak.local", "Admin123")
        with pytest.raises(Exception) as exc_info:
            client.data.download("12345678-1234-1234-1234-123456789abd")

        # 409 maps to base KayakError
        assert exc_info.value.status_code == 409
