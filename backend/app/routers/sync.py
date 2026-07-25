from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.sync_preference import SyncPreference
from app.models.user import User
from app.schemas.sync import SyncPreferenceResponse, SyncPreferenceUpsert

router = APIRouter(prefix="/sync/preferences", tags=["sync"])


@router.get("", response_model=list[SyncPreferenceResponse])
async def list_preferences(user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.scalars(select(SyncPreference).where(SyncPreference.user_id == user.id))
    return list(result)


@router.post("", response_model=SyncPreferenceResponse)
async def upsert_preference(payload: SyncPreferenceUpsert, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    query = select(SyncPreference).where(
        SyncPreference.user_id == user.id,
        SyncPreference.device_id == payload.device_id,
        SyncPreference.source_type == payload.source_type,
        SyncPreference.source_id == payload.source_id,
    )
    preference = await db.scalar(query)
    if preference is None:
        preference = SyncPreference(user_id=user.id, **payload.model_dump())
        db.add(preference)
    else:
        for key, value in payload.model_dump().items():
            setattr(preference, key, value)
    await db.commit()
    await db.refresh(preference)
    return preference
