from datetime import datetime
from pydantic import BaseModel, ConfigDict, Field

class FriendRequestIn(BaseModel):
    user_id: int
class FriendshipOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int; requester_id: int; addressee_id: int; status: str; created_at: datetime
class SharedAlbumIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
class SharedAlbumMemberIn(BaseModel):
    user_id: int
    permission: str = Field(pattern='^(viewer|editor|admin)$')
class ShareLinkIn(BaseModel):
    resource_type: str
    resource_id: str
    password: str | None = None
    allow_download: bool = False
    expires_hours: int = Field(default=24, ge=1, le=168)
