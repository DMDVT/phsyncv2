from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import and_, or_, select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.dependencies import get_current_user
from app.models.social import Friendship, Notification
from app.models.user import User
from app.schemas.social import FriendRequestIn
router=APIRouter(prefix="/friends", tags=["friends"])

@router.post("/request")
async def request_friend(data: FriendRequestIn, me: User=Depends(get_current_user), db: AsyncSession=Depends(get_db)):
    if data.user_id==me.id: raise HTTPException(400,"Cannot friend yourself")
    target=await db.get(User,data.user_id)
    if not target: raise HTTPException(404,"User not found")
    existing=(await db.execute(select(Friendship).where(or_(and_(Friendship.requester_id==me.id,Friendship.addressee_id==data.user_id),and_(Friendship.requester_id==data.user_id,Friendship.addressee_id==me.id))))).scalar_one_or_none()
    if existing: raise HTTPException(409,"Friendship already exists")
    row=Friendship(requester_id=me.id,addressee_id=data.user_id)
    db.add_all([row,Notification(user_id=data.user_id,type="friend_request",title="New friend request",body=f"{me.username} sent you a friend request",payload={"requester_id":me.id})])
    await db.commit(); await db.refresh(row)
    return row

@router.get("")
async def list_friends(me: User=Depends(get_current_user), db: AsyncSession=Depends(get_db)):
    rows=(await db.execute(select(Friendship).where(Friendship.status=="accepted",or_(Friendship.requester_id==me.id,Friendship.addressee_id==me.id)))).scalars().all()
    ids=[r.addressee_id if r.requester_id==me.id else r.requester_id for r in rows]
    users=(await db.execute(select(User).where(User.id.in_(ids)))).scalars().all() if ids else []
    return [{"id":u.id,"username":u.username,"display_name":u.display_name,"avatar_url":u.avatar_url} for u in users]

@router.get("/requests")
async def requests(me: User=Depends(get_current_user), db: AsyncSession=Depends(get_db)):
    return (await db.execute(select(Friendship).where(Friendship.addressee_id==me.id,Friendship.status=="pending"))).scalars().all()

@router.post("/accept/{friendship_id}")
async def accept(friendship_id:int, me:User=Depends(get_current_user), db:AsyncSession=Depends(get_db)):
    row=await db.get(Friendship,friendship_id)
    if not row or row.addressee_id!=me.id: raise HTTPException(404,"Request not found")
    row.status="accepted"; db.add(Notification(user_id=row.requester_id,type="friend_accepted",title="Friend request accepted",body=f"{me.username} accepted your request",payload={"user_id":me.id}))
    await db.commit(); return {"status":"accepted"}

@router.post("/decline/{friendship_id}")
async def decline(friendship_id:int, me:User=Depends(get_current_user), db:AsyncSession=Depends(get_db)):
    row=await db.get(Friendship,friendship_id)
    if not row or row.addressee_id!=me.id: raise HTTPException(404,"Request not found")
    await db.delete(row); await db.commit(); return {"status":"declined"}

@router.post("/block/{user_id}")
async def block(user_id:int, me:User=Depends(get_current_user), db:AsyncSession=Depends(get_db)):
    row=(await db.execute(select(Friendship).where(or_(and_(Friendship.requester_id==me.id,Friendship.addressee_id==user_id),and_(Friendship.requester_id==user_id,Friendship.addressee_id==me.id))))).scalar_one_or_none()
    if row: row.requester_id=me.id; row.addressee_id=user_id; row.status="blocked"
    else: db.add(Friendship(requester_id=me.id,addressee_id=user_id,status="blocked"))
    await db.commit(); return {"status":"blocked"}

@router.delete("/{user_id}")
async def remove(user_id:int, me:User=Depends(get_current_user), db:AsyncSession=Depends(get_db)):
    row=(await db.execute(select(Friendship).where(or_(and_(Friendship.requester_id==me.id,Friendship.addressee_id==user_id),and_(Friendship.requester_id==user_id,Friendship.addressee_id==me.id))))).scalar_one_or_none()
    if row: await db.delete(row); await db.commit()
    return {"status":"removed"}
