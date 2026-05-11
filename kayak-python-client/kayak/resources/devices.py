"""Devices resource API."""

from typing import Optional

from kayak.models import Device
from kayak.resources.base import BaseResource
from kayak.utils import validate_uuid


class DevicesAPI(BaseResource):
    """API for managing devices."""

    _base_path = "/devices"

    def list(
        self,
        *,
        workbench_id: Optional[str] = None,
    ) -> list[Device]:
        """List devices with optional filtering.

        Args:
            workbench_id: Filter by workbench ID.

        Returns:
            List of Device models.
        """
        params: dict[str, str] = {}
        if workbench_id is not None:
            params["workbench_id"] = workbench_id
        return self._list("", params=params, model_class=Device)

    def get(self, device_id: str) -> Device:
        """Get a single device by ID.

        Args:
            device_id: The device UUID.

        Returns:
            Device model.
        """
        validate_uuid(device_id, "device_id")
        return self._get(f"/{device_id}", model_class=Device)
