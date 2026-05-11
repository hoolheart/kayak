"""Kayak Python SDK - Python client for the Kayak scientific research platform."""

from kayak.auth import AuthManager
from kayak.client import KayakClient
from kayak.exceptions import (
    AuthenticationError,
    ConnectionError,
    KayakError,
    NotFoundError,
    ServerError,
    ValidationError,
)
from kayak.models import Device, Experiment, Method, Workbench
from kayak.resources.data import DataDownload

__all__ = [
    "AuthManager",
    "KayakClient",
    "KayakError",
    "AuthenticationError",
    "NotFoundError",
    "ServerError",
    "ConnectionError",
    "ValidationError",
    "Workbench",
    "Device",
    "Method",
    "Experiment",
    "DataDownload",
]

__version__ = "0.1.0"
