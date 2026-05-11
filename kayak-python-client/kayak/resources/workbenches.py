"""Workbenches resource API."""

from typing import Optional

from kayak.models import Workbench
from kayak.resources.base import BaseResource
from kayak.utils import validate_uuid


class WorkbenchesAPI(BaseResource):
    """API for managing workbenches."""

    _base_path = "/workbenches"

    def list(
        self,
        *,
        scope: Optional[str] = None,
        team_id: Optional[str] = None,
    ) -> list[Workbench]:
        """List workbenches with optional filtering.

        Args:
            scope: Filter by scope (e.g., "team").
            team_id: Filter by team ID.

        Returns:
            List of Workbench models.
        """
        params: dict[str, str] = {}
        if scope is not None:
            params["scope"] = scope
        if team_id is not None:
            params["team_id"] = team_id
        return self._list("", params=params, model_class=Workbench)

    def get(self, workbench_id: str) -> Workbench:
        """Get a single workbench by ID.

        Args:
            workbench_id: The workbench UUID.

        Returns:
            Workbench model.
        """
        validate_uuid(workbench_id, "workbench_id")
        return self._get(f"/{workbench_id}", model_class=Workbench)
