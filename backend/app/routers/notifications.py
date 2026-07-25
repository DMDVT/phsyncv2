from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.social import Notification
from app.models.user import User
router=APIRouter(prefix="/notifications",tags=["notifications"])
@router.get("")
async def list_all(me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    return (await db.execute(select(Notification).where(Notification.user_id==me.id).order_by(Notification.created_at.desc()).limit(100))).scalars().all()
@router.patch("/{notification_id}/read")
async def mark_read(notification_id:int,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    row=await db.get(Notification,notification_id)
    if not row or row.user_id!=me.id: raise HTTPException(404,"Notification not found")
    row.is_read=True; await db.commit(); return {"status":"read"}
@router.post("/read-all")
async def read_all(me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    await db.execute(update(Notification).where(Notification.user_id==me.id).values(is_read=True)); await db.commit(); return {"status":"read"}
