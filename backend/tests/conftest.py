import os
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///./test_photosync.db"
os.environ["SECRET_KEY"] = "test-secret"
