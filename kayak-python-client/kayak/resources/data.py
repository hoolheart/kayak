"""Data download and conversion API."""

import io
from typing import TYPE_CHECKING, Any, Optional

import h5py

from kayak.resources.base import BaseResource
from kayak.utils import validate_time_range, validate_uuid

if TYPE_CHECKING:
    import numpy as np
    import pandas as pd


class DataDownload:
    """Represents downloaded experiment data.

    Provides lazy access to HDF5 contents with format conversion.
    Memory-efficient: raw bytes stored in memory; HDF5 parsed on demand.
    """

    def __init__(self, experiment_id: str, raw_data: bytes) -> None:
        self.experiment_id = experiment_id
        self._raw_data = raw_data
        self._h5_file: Optional[h5py.File] = None
        self._h5_io: Optional[io.BytesIO] = None

    def _ensure_h5_open(self) -> h5py.File:
        """Lazy initialization of HDF5 file handle."""
        if self._h5_file is None:
            self._h5_io = io.BytesIO(self._raw_data)
            self._h5_file = h5py.File(self._h5_io, "r")
        return self._h5_file

    def save(self, path: str) -> None:
        """Save raw HDF5 data to local file."""
        with open(path, "wb") as f:
            f.write(self._raw_data)

    def list_points(self) -> list[str]:
        """List all available measurement point paths."""
        h5 = self._ensure_h5_open()
        points: list[str] = []
        if "raw_data" in h5:
            for device_id in h5["raw_data"].keys():
                device_group = h5["raw_data"][device_id]
                for key in device_group.keys():
                    if not key.endswith("_meta"):
                        points.append(f"{device_id}/{key}")
        return points

    def get_point_data(self, point_path: str) -> tuple:
        """Get timestamps and values for a specific point.

        Returns:
            Tuple of (timestamps: ndarray, values: ndarray).
        """
        import numpy as np

        h5 = self._ensure_h5_open()
        dataset = h5[f"raw_data/{point_path}"]
        data = dataset[:]
        return data[:, 0], data[:, 1]

    def to_dataframe(self) -> "pd.DataFrame":
        """Convert HDF5 data to pandas DataFrame.

        Columns: timestamp, {point_name_1}, {point_name_2}, ...
        Rows aligned by timestamp (outer join).

        Requires `pandas` extra to be installed.
        """
        try:
            import pandas as pd
        except ImportError as e:
            raise ImportError(
                "pandas is required for to_dataframe(). "
                "Install with: pip install kayak[pandas]"
            ) from e

        h5 = self._ensure_h5_open()

        if "raw_data" not in h5 or not list(h5["raw_data"].keys()):
            return pd.DataFrame(columns=["timestamp"])

        df = None
        for device_id in h5["raw_data"].keys():
            device_group = h5["raw_data"][device_id]
            for key in device_group.keys():
                if key.endswith("_meta"):
                    continue

                point_data = device_group[key][:]
                timestamps = point_data[:, 0]
                values = point_data[:, 1]

                point_df = pd.DataFrame({
                    "timestamp": pd.to_datetime(timestamps, unit="ms"),
                    key: values,
                })

                if df is None:
                    df = point_df
                else:
                    df = pd.merge(df, point_df, on="timestamp", how="outer")

        if df is None:
            return pd.DataFrame(columns=["timestamp"])

        df = df.sort_values("timestamp").reset_index(drop=True)
        return df

    def to_numpy(self) -> "np.ndarray":
        """Convert HDF5 data to numpy ndarray.

        Returns ndarray with shape (samples, 1 + n_points).
        Column 0 is timestamp, columns 1..N are point values.
        Missing values filled with NaN.

        Requires `numpy` extra to be installed.
        """
        try:
            import numpy as np
        except ImportError as e:
            raise ImportError(
                "numpy is required for to_numpy(). "
                "Install with: pip install kayak[numpy]"
            ) from e

        h5 = self._ensure_h5_open()

        if "raw_data" not in h5 or not list(h5["raw_data"].keys()):
            return np.array([]).reshape(0, 0)

        all_data: dict[str, Any] = {}
        for device_id in h5["raw_data"].keys():
            device_group = h5["raw_data"][device_id]
            for key in device_group.keys():
                if key.endswith("_meta"):
                    continue
                data = device_group[key][:]
                all_data[key] = data

        if not all_data:
            return np.array([]).reshape(0, 0)

        all_timestamps: set = set()
        for data in all_data.values():
            all_timestamps.update(data[:, 0])
        timestamps = np.array(sorted(all_timestamps))

        n_samples = len(timestamps)
        n_points = len(all_data)
        result = np.full((n_samples, 1 + n_points), np.nan)
        result[:, 0] = timestamps

        for col_idx, (point_name, data) in enumerate(all_data.items(), start=1):
            ts_to_val = dict(zip(data[:, 0], data[:, 1]))
            for row_idx, ts in enumerate(timestamps):
                if ts in ts_to_val:
                    result[row_idx, col_idx] = ts_to_val[ts]

        return result

    def close(self) -> None:
        """Close HDF5 file handle and free resources."""
        if self._h5_file is not None:
            self._h5_file.close()
            self._h5_file = None
        if self._h5_io is not None:
            self._h5_io.close()
            self._h5_io = None

    def __enter__(self) -> "DataDownload":
        return self

    def __exit__(self, exc_type: Any, exc_val: Any, exc_tb: Any) -> None:
        self.close()


class DataAPI(BaseResource):
    """API for downloading experiment data."""

    _base_path = "/experiments"

    def download(
        self,
        experiment_id: str,
        *,
        start_time: Optional[str] = None,
        end_time: Optional[str] = None,
    ) -> DataDownload:
        """Download experiment data as HDF5.

        Args:
            experiment_id: The experiment UUID.
            start_time: Optional ISO 8601 start time filter.
            end_time: Optional ISO 8601 end time filter.

        Returns:
            DataDownload instance wrapping the raw HDF5 bytes.
        """
        validate_uuid(experiment_id, "experiment_id")

        if start_time and end_time:
            validate_time_range(start_time, end_time)

        params: dict[str, str] = {}
        if start_time:
            params["start_time"] = start_time
        if end_time:
            params["end_time"] = end_time

        response = self._request(
            "GET",
            f"/{experiment_id}/data/download",
            params=params,
        )
        return DataDownload(experiment_id, response.content)
