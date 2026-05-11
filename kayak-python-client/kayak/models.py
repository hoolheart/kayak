"""Pydantic models for Kayak API responses."""

from datetime import datetime
from typing import Any, Optional

from pydantic import BaseModel, Field, field_validator


class KayakBaseModel(BaseModel):
    """Base model with common configuration."""

    model_config = {
        "populate_by_name": True,
        "str_strip_whitespace": True,
    }


class Workbench(KayakBaseModel):
    """Workbench model."""

    id: str = Field(..., description="Workbench UUID")
    name: str = Field(..., description="Workbench name")
    description: Optional[str] = Field(None, description="Workbench description")
    owner_type: Optional[str] = None
    owner_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class Device(KayakBaseModel):
    """Device model."""

    id: str
    name: str
    workbench_id: Optional[str] = None
    parent_id: Optional[str] = None
    protocol_type: Optional[str] = None
    protocol_params: Optional[dict[str, Any]] = None
    manufacturer: Optional[str] = None
    model: Optional[str] = None
    sn: Optional[str] = None
    created_at: Optional[datetime] = None


class Method(KayakBaseModel):
    """Method model."""

    id: str
    name: str
    description: Optional[str] = None
    definition: Optional[dict[str, Any]] = None
    parameter_schema: Optional[dict[str, Any]] = None
    owner_type: Optional[str] = None
    owner_id: Optional[str] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class Experiment(KayakBaseModel):
    """Experiment model."""

    id: str
    name: Optional[str] = None
    method_id: Optional[str] = None
    user_id: Optional[str] = None
    parameters: Optional[dict[str, Any]] = None
    status: Optional[str] = None
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    @field_validator("status")
    @classmethod
    def validate_status(cls, v: Optional[str]) -> Optional[str]:
        valid = {"idle", "loaded", "running", "paused", "completed", "error"}
        if v is not None and v not in valid:
            raise ValueError(f"Invalid status: {v}")
        return v


class TokenResponse(KayakBaseModel):
    """Token response model."""

    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int = Field(..., description="Token lifetime in seconds")
