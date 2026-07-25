from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import get_settings
from app.database import create_schema
from app.routers import auth, friends, metadata, notifications, share_links, shared_albums, sharing, sync, users

settings = get_settings()


@asynccontextmanager
async def lifespan(_: FastAPI):
    await create_schema()
    yield


app = FastAPI(title=settings.app_name, version="0.4.0", lifespan=lifespan)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origin_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(sync.router)
app.include_router(metadata.router)
app.include_router(friends.router)
app.include_router(sharing.router)
app.include_router(shared_albums.router)
app.include_router(notifications.router)
app.include_router(share_links.router)


@app.get("/health")
async def health() -> dict[str, str]:
    return {"status": "ok", "service": settings.app_name}
