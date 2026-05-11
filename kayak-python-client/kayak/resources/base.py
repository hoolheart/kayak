"""Base resource class for all Kayak API resources."""

from abc import ABC
from typing import TYPE_CHECKING, Any, Optional, Type, TypeVar

import httpx

from kayak.models import KayakBaseModel

if TYPE_CHECKING:
    from kayak.http_client import _HTTPClient

T = TypeVar("T", bound=KayakBaseModel)


class BaseResource(ABC):
    """Base class for all resource APIs.

    Provides common CRUD patterns and path construction.
    """

    _base_path: str = "/"

    def __init__(self, http_client: "_HTTPClient") -> None:
        self._http = http_client

    def _request(
        self,
        method: str,
        path: str,
        params: Optional[dict] = None,
        **kwargs: Any,
    ) -> httpx.Response:
        """Make an authenticated request."""
        full_path = f"{self._base_path}{path}"
        return self._http.request(method, full_path, params=params, **kwargs)

    def _list(
        self,
        path: str = "",
        params: Optional[dict] = None,
        model_class: Type[T] = KayakBaseModel,  # type: ignore[assignment]
    ) -> list[T]:
        """List resources with optional filtering."""
        response = self._request("GET", path, params=params)
        data = response.json()["data"]
        if not isinstance(data, list):
            return []
        return [model_class(**item) for item in data]

    def _get(
        self,
        path: str,
        model_class: Type[T] = KayakBaseModel,  # type: ignore[assignment]
    ) -> T:
        """Get a single resource by path."""
        response = self._request("GET", path)
        data = response.json()["data"]
        return model_class(**data)
