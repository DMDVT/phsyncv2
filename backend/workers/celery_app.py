from celery import Celery
from app.config import get_settings

settings = get_settings()
celery = Celery("photosync", broker=settings.redis_url, backend=settings.redis_url)
celery.conf.beat_schedule = {
    "cleanup-expired-hourly": {
        "task": "workers.tasks.cleanup_expired.cleanup_expired",
        "schedule": 3600.0,
    }
}
celery.autodiscover_tasks(["workers.tasks"])
