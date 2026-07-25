from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.social import ShareLink
from app.models.user import User
from app.schemas.social import ShareLinkIn
from app.services.auth_service import hash_password, verify_password
router=APIRouter(prefix="/share-links",tags=["share links"])
@router.post("")
async def create(data:ShareLinkIn,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    row=ShareLink(owner_id=me.id,resource_type=data.resource_type,resource_id=data.resource_id,password_hash=hash_password(data.password) if data.password else None,allow_download=data.allow_download,expires_at=datetime.now(timezone.utc)+timedelta(hours=data.expires_hours)); db.add(row); await db.commit(); await db.refresh(row); return {"id":row.id,"expires_at":row.expires_at,"allow_download":row.allow_download}
@router.get("/{link_id}")
async def inspect(link_id:str,password:str|None=None,db:AsyncSession=Depends(get_db)):
    row=await db.get(ShareLink,link_id)
    if not row or row.is_revoked or row.expires_at<datetime.now(timezone.utc): raise HTTPException(404,"Link unavailable")
    if row.password_hash and (not password or not verify_password(password,row.password_hash)): raise HTTPException(401,"Password required")
    return {"resource_type":row.resource_type,"resource_id":row.resource_id,"allow_download":row.allow_download,"expires_at":row.expires_at}
@router.delete("/{link_id}")
async def revoke(link_id:str,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    row=await db.get(ShareLink,link_id)
    if not row or row.owner_id!=me.id: raise HTTPException(404,"Link not found")
    row.is_revoked=True; await db.commit(); return {"status":"revoked"}
