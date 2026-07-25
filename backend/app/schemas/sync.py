from datetime import datetime
from typing import Any
from pydantic import BaseModel, ConfigDict, Field


class SyncPreferenceUpsert(BaseModel):
    device_id: str = Field(min_length=1, max_length=128)
    source_type: str = Field(min_length=1, max_length=40)
    source_id: str = Field(min_length=1, max_length=255)
    source_name: str = Field(min_length=1, max_length=255)
    is_enabled: bool = True
    media_count: int = Field(default=0, ge=0)


class SyncPreferenceResponse(SyncPreferenceUpsert):
    model_config = ConfigDict(from_attributes=True)
    id: int
    updated_at: datetime


class MetadataUpsert(BaseModel):
    data_type: str = Field(min_length=1, max_length=40)
    data_key: str = Field(min_length=1, max_length=255)
    data_value: dict[str, Any]
    version: int = Field(default=1, ge=1)


class MetadataResponse(MetadataUpsert):
    model_config = ConfigDict(from_attributes=True)
    id: int
    updated_at: datetime
