"""Tests for data conversion (TC-SDK-032 ~ 037)."""

import io

import h5py
import numpy as np
import pandas as pd
import pytest

from kayak.resources.data import DataDownload


class TestDataConversion:
    """TC-SDK-032 ~ 037"""

    def _create_multi_point_hdf5(self) -> bytes:
        """Create HDF5 with multiple points."""
        bio = io.BytesIO()
        with h5py.File(bio, "w") as f:
            raw = f.create_group("raw_data")
            dev = raw.create_group("dev-1")
            # Nx2: [timestamp, value]
            dev.create_dataset("temperature", data=[
                [1714521600000.0, 25.3],
                [1714521601000.0, 25.4],
            ])
            dev.create_dataset("pressure", data=[
                [1714521600000.0, 101.3],
                [1714521601000.0, 101.4],
            ])
        return bio.getvalue()

    def _create_empty_hdf5(self) -> bytes:
        """Create empty HDF5 (no raw_data)."""
        bio = io.BytesIO()
        with h5py.File(bio, "w") as f:
            f.create_group("metadata")
        return bio.getvalue()

    def _create_single_point_hdf5(self) -> bytes:
        """Create HDF5 with single point."""
        bio = io.BytesIO()
        with h5py.File(bio, "w") as f:
            raw = f.create_group("raw_data")
            dev = raw.create_group("dev-1")
            dev.create_dataset("temperature", data=[
                [1714521600000.0, 25.3],
                [1714521601000.0, 25.4],
            ])
        return bio.getvalue()

    def test_to_dataframe(self):
        """TC-SDK-032: Convert to pandas DataFrame — Success"""
        raw = self._create_multi_point_hdf5()
        data = DataDownload("exp-123", raw)

        df = data.to_dataframe()

        assert isinstance(df, pd.DataFrame)
        assert "timestamp" in df.columns
        assert "temperature" in df.columns
        assert "pressure" in df.columns
        assert len(df) == 2
        assert df["temperature"].iloc[0] == 25.3

    def test_to_dataframe_missing_pandas(self, monkeypatch):
        """TC-SDK-033: Convert to pandas DataFrame — Missing Optional Dependency"""
        import sys

        # Remove pandas from modules
        monkeypatch.setitem(sys.modules, "pandas", None)

        raw = self._create_multi_point_hdf5()
        data = DataDownload("exp-123", raw)

        with pytest.raises(ImportError, match="pandas is required"):
            data.to_dataframe()

    def test_to_numpy(self):
        """TC-SDK-034: Convert to numpy ndarray — Success"""
        raw = self._create_multi_point_hdf5()
        data = DataDownload("exp-123", raw)

        arr = data.to_numpy()

        assert isinstance(arr, np.ndarray)
        assert arr.shape[0] == 2
        assert not np.isnan(arr).any()  # Both points share timestamps

    def test_to_numpy_missing_numpy(self, monkeypatch):
        """TC-SDK-035: Convert to numpy ndarray — Missing Optional Dependency"""
        import sys

        monkeypatch.setitem(sys.modules, "numpy", None)

        raw = self._create_multi_point_hdf5()
        data = DataDownload("exp-123", raw)

        with pytest.raises(ImportError, match="numpy is required"):
            data.to_numpy()

    def test_empty_hdf5(self):
        """TC-SDK-036: Data Conversion — Empty HDF5 (No Points)"""
        raw = self._create_empty_hdf5()
        data = DataDownload("exp-123", raw)

        df = data.to_dataframe()
        assert isinstance(df, pd.DataFrame)
        assert "timestamp" in df.columns
        assert len(df) == 0

        arr = data.to_numpy()
        assert isinstance(arr, np.ndarray)
        assert arr.shape == (0, 0)

    def test_single_point(self):
        """TC-SDK-037: Data Conversion — Single Point Dataset"""
        raw = self._create_single_point_hdf5()
        data = DataDownload("exp-123", raw)

        df = data.to_dataframe()
        assert isinstance(df, pd.DataFrame)
        assert "timestamp" in df.columns
        assert "temperature" in df.columns
        assert len(df) == 2
