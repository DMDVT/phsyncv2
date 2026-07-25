from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.social import Notification, SharedAlbum, SharedAlbumMember
from app.models.user import User
from app.schemas.social import SharedAlbumIn, SharedAlbumMemberIn
router=APIRouter(prefix="/shared-albums",tags=["shared albums"])

@router.post("")
async def create(data:SharedAlbumIn,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    album=SharedAlbum(owner_id=me.id,name=data.name); db.add(album); await db.flush(); db.add(SharedAlbumMember(album_id=album.id,user_id=me.id,permission="admin")); await db.commit(); await db.refresh(album); return album
@router.get("")
async def list_all(me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    ids=select(SharedAlbumMember.album_id).where(SharedAlbumMember.user_id==me.id)
    return (await db.execute(select(SharedAlbum).where(or_(SharedAlbum.owner_id==me.id,SharedAlbum.id.in_(ids))))).scalars().all()
@router.post("/{album_id}/members")
async def add_member(album_id:int,data:SharedAlbumMemberIn,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    album=await db.get(SharedAlbum,album_id)
    if not album or album.owner_id!=me.id: raise HTTPException(403,"Owner access required")
    row=SharedAlbumMember(album_id=album_id,user_id=data.user_id,permission=data.permission); db.add_all([row,Notification(user_id=data.user_id,type="album_update",title="Shared album invitation",body=f"You were added to {album.name}",payload={"album_id":album_id})]); await db.commit(); return row
@router.delete("/{album_id}/members/{user_id}")
async def remove_member(album_id:int,user_id:int,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    album=await db.get(SharedAlbum,album_id)
    if not album or album.owner_id!=me.id: raise HTTPException(403,"Owner access required")
    row=(await db.execute(select(SharedAlbumMember).where(SharedAlbumMember.album_id==album_id,SharedAlbumMember.user_id==user_id))).scalar_one_or_none()
    if row: await db.delete(row); await db.commit()
    return {"status":"removed"}
@router.delete("/{album_id}")
async def delete(album_id:int,me:User=Depends(get_current_user),db:AsyncSession=Depends(get_db)):
    album=await db.get(SharedAlbum,album_id)
    if not album or album.owner_id!=me.id: raise HTTPException(403,"Owner access required")
    await db.delete(album); await db.commit(); return {"status":"deleted"}
