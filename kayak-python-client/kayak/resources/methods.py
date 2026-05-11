"""Methods resource API."""

from kayak.models import Method
from kayak.resources.base import BaseResource


class MethodsAPI(BaseResource):
    """API for managing methods."""

    _base_path = "/methods"

    def list(self) -> list[Method]:
        """List all methods.

        Returns:
            List of Method models.
        """
        return self._list("", model_class=Method)

    def get(self, method_id: str) -> Method:
        """Get a single method by ID.

        Args:
            method_id: The method UUID.

        Returns:
            Method model.
        """
        from kayak.utils import validate_uuid

        validate_uuid(method_id, "method_id")
        return self._get(f"/{method_id}", model_class=Method)
