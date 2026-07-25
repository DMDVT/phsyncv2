from datetime import datetime, timezone
from pathlib import Path
from uuid import uuid4
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile
from fastapi.responses import FileResponse
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.config import get_settings
from app.database import get_db
from app.dependencies import get_current_user
from app.models.social import Friendship, Notification, SharedMedia, ShareHistory
from app.models.user import User
router=APIRouter(prefix="/share",tags=["sharing"]); settings=get_settings()

async def ensure_friends(db,a,b):
    row=(await db.execute(select(Friendship).where(Friendship.status=="accepted",or_(and_(Friendship.requester_id==a,Friendship.addressee_id==b),and_(Friendship.requester_id==b,Friendship.addressee_id==a))))).scalar_one_or_none()
    if not row: raise HTTPException(403,"Sharing is limited to friends")

@router.post("/send")
async def send(recipient_id:int=Form(...),caption:str|None=Form(None),file:UploadFile=File(...),me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    await ensure_friends(db,me.id,recipient_id)
    share_id=str(uuid4()); safe=Path(file.filename or "shared.bin").name; target=Path(settings.temp_storage_path)/f"{share_id}_{safe}"
    size=0
    with target.open("wb") as out:
        while chunk:=await file.read(1024*1024): size+=len(chunk); out.write(chunk)
    media_type="video" if (file.content_type or "").startswith("video/") else "photo"
    row=SharedMedia(id=share_id,sender_id=me.id,recipient_id=recipient_id,file_path=str(target),file_name=safe,file_size=size,media_type=media_type,caption=caption)
    db.add_all([row,Notification(user_id=recipient_id,type="share_received",title="New shared media",body=f"{me.username} shared {safe}",payload={"share_id":share_id}) ,ShareHistory(sender_id=me.id,recipient_id=recipient_id,media_type=media_type)])
    await db.commit(); return {"id":share_id,"status":"pending","expires_at":row.expires_at}

@router.get("/pending")
async def pending(me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    rows=(await db.execute(select(SharedMedia).where(SharedMedia.recipient_id==me.id,SharedMedia.status=="pending",SharedMedia.expires_at>datetime.now(timezone.utc)))).scalars().all()
    return [{"id":r.id,"sender_id":r.sender_id,"file_name":r.file_name,"file_size":r.file_size,"media_type":r.media_type,"caption":r.caption,"created_at":r.created_at} for r in rows]

@router.get("/download/{share_id}")
async def download(share_id:str,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    row=await db.get(SharedMedia,share_id)
    if not row or row.recipient_id!=me.id or row.status!="pending": raise HTTPException(404,"Share not available")
    if not Path(row.file_path).exists(): raise HTTPException(410,"Temporary file expired")
    return FileResponse(row.file_path,filename=row.file_name)

@router.post("/confirm/{share_id}")
async def confirm(share_id:str,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    row=await db.get(SharedMedia,share_id)
    if not row or row.recipient_id!=me.id: raise HTTPException(404,"Share not found")
    Path(row.file_path).unlink(missing_ok=True); row.status="delivered"; row.delivered_at=datetime.now(timezone.utc); row.file_path=""
    await db.commit(); return {"status":"delivered"}

@router.get("/history")
async def history(me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    return (await db.execute(select(ShareHistory).where(or_(ShareHistory.sender_id==me.id,ShareHistory.recipient_id==me.id)).order_by(ShareHistory.shared_at.desc()))).scalars().all()
