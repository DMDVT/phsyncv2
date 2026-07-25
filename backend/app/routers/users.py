from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.auth import UserResponse

router = APIRouter(prefix="/users", tags=["users"])


class ProfilePatch(BaseModel):
    display_name: str | None = Field(default=None, max_length=100)
    avatar_url: str | None = Field(default=None, max_length=500)


@router.get("/me", response_model=UserResponse)
async def me(user: User = Depends(get_current_user)) -> User:
    return user


@router.patch("/me", response_model=UserResponse)
async def update_me(payload: ProfilePatch, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)) -> User:
    if "display_name" in payload.model_fields_set:
        user.display_name = payload.display_name
    if "avatar_url" in payload.model_fields_set:
        user.avatar_url = payload.avatar_url
    await db.commit()
    await db.refresh(user)
    return user
