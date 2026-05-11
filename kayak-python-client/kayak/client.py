"""Main KayakClient entry point for the Python SDK."""

from types import TracebackType
from typing import Optional, Type

from kayak.auth import AuthManager
from kayak.http_client import _HTTPClient
from kayak.resources.data import DataAPI
from kayak.resources.devices import DevicesAPI
from kayak.resources.experiments import ExperimentsAPI
from kayak.resources.methods import MethodsAPI
from kayak.resources.workbenches import WorkbenchesAPI
from kayak.utils import validate_base_url


class KayakClient:
    """Main client for interacting with the Kayak REST API.

    Supports context manager usage for automatic resource cleanup:

        with KayakClient(base_url="http://localhost:8080") as client:
            client.login("admin@kayak.local", "Admin123")
            workbenches = client.workbenches.list()
    """

    def __init__(
        self,
        base_url: str,
        *,
        timeout: float = 30.0,
    ) -> None:
        """Initialize the Kayak client.

        Args:
            base_url: The base URL of the Kayak backend (e.g., http://localhost:8080).
            timeout: Default HTTP request timeout in seconds.
        """
        self.base_url = validate_base_url(base_url)
        self._http = _HTTPClient(self.base_url, timeout=timeout)
        self.auth = AuthManager(self._http)
        self._http.auth = self.auth

        # Resource APIs
        self.workbenches = WorkbenchesAPI(self._http)
        self.devices = DevicesAPI(self._http)
        self.methods = MethodsAPI(self._http)
        self.experiments = ExperimentsAPI(self._http)
        self.data = DataAPI(self._http)

        self._entered = False

    def login(self, email: str, password: str) -> bool:
        """Authenticate with email and password.

        Args:
            email: User email address.
            password: User password.

        Returns:
            True on success.
        """
        return self.auth.login(email, password)

    def logout(self) -> None:
        """Log out and clear authentication state."""
        self.auth.logout()

    def close(self) -> None:
        """Close the HTTP client and release resources."""
        self._http.close()

    def __enter__(self) -> "KayakClient":
        self._entered = True
        return self

    def __exit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None:
        if self.auth.is_authenticated():
            try:
                self.logout()
            except Exception:
                pass
        self.close()
        self._entered = False
