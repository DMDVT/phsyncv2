from datetime import datetime, timezone
from pathlib import Path
from sqlalchemy import select
from app.database import SessionLocal
from app.models.social import SharedMedia
from workers.celery_app import celery_app

@celery_app.task(name="cleanup_expired_shares")
def cleanup_expired_shares() -> int:
    import asyncio
    return asyncio.run(_cleanup())

async def _cleanup() -> int:
    removed = 0
    async with SessionLocal() as db:
        rows = (await db.execute(select(SharedMedia).where(SharedMedia.status == "pending", SharedMedia.expires_at <= datetime.now(timezone.utc)))).scalars().all()
        for row in rows:
            Path(row.file_path).unlink(missing_ok=True)
            row.file_path = ""
            row.status = "expired"
            removed += 1
        await db.commit()
    return removed
