"""Experiments resource API."""

from typing import Optional

from kayak.models import Experiment
from kayak.resources.base import BaseResource
from kayak.utils import validate_uuid


class ExperimentsAPI(BaseResource):
    """API for managing experiments."""

    _base_path = "/experiments"

    def list(
        self,
        *,
        status: Optional[str] = None,
    ) -> list[Experiment]:
        """List experiments with optional filtering.

        Args:
            status: Filter by experiment status.

        Returns:
            List of Experiment models.
        """
        params: dict[str, str] = {}
        if status is not None:
            params["status"] = status
        return self._list("", params=params, model_class=Experiment)

    def get(self, experiment_id: str) -> Experiment:
        """Get a single experiment by ID.

        Args:
            experiment_id: The experiment UUID.

        Returns:
            Experiment model.
        """
        validate_uuid(experiment_id, "experiment_id")
        return self._get(f"/{experiment_id}", model_class=Experiment)
