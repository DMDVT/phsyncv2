from datetime import datetime
from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.metadata import MetadataSync
from app.models.user import User
from app.schemas.sync import MetadataResponse, MetadataUpsert

router = APIRouter(prefix="/metadata", tags=["metadata"])


@router.post("/sync", response_model=MetadataResponse)
async def push_metadata(payload: MetadataUpsert, user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    query = select(MetadataSync).where(
        MetadataSync.user_id == user.id,
        MetadataSync.data_type == payload.data_type,
        MetadataSync.data_key == payload.data_key,
    )
    row = await db.scalar(query)
    if row is None:
        row = MetadataSync(user_id=user.id, **payload.model_dump())
        db.add(row)
    elif payload.version >= row.version:
        row.data_value = payload.data_value
        row.version = payload.version + 1
    await db.commit()
    await db.refresh(row)
    return row


@router.get("/sync", response_model=list[MetadataResponse])
async def pull_metadata(
    since: datetime | None = Query(default=None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(MetadataSync).where(MetadataSync.user_id == user.id)
    if since is not None:
        query = query.where(MetadataSync.updated_at > since)
    return list(await db.scalars(query.order_by(MetadataSync.updated_at.asc())))
