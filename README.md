# PhotoSync deployment candidate

PhotoSync is a privacy-first Flutter gallery with an optional FastAPI social backend.

## What is included

- Android Flutter client with device media permission handling, gallery grid, viewer, albums, filename/tag search, memories, vault PIN, storage analytics, account login/registration, and backend health checks.
- FastAPI backend with JWT authentication, users, friends, temporary relay sharing, shared albums, notifications, share links, sync preferences, and metadata sync.
- Railway Docker deployment configuration.
- GitHub Actions for backend validation and automatic debug/release APK builds.
- Codemagic YAML as an alternative Android builder.
- Docker Compose for local PostgreSQL, Redis, API, Celery worker, and Celery beat.

## Deploy backend to Railway

1. Create a Railway service from this repository.
2. Set its Root Directory to `/backend`.
3. Generate a public domain.
4. Set `SECRET_KEY` to a long random value.
5. For quick testing, leave `DATABASE_URL` unset to use SQLite. For persistent production accounts, add Railway PostgreSQL and reference its `DATABASE_URL`.
6. Add a persistent volume mounted at `/app/temp_shares` when testing relay uploads.
7. Confirm `https://YOUR_DOMAIN/health` and `/docs` work.

Railway PostgreSQL URLs are normalized automatically to SQLAlchemy's async `asyncpg` form.

## Build APK on GitHub

1. In repository Settings → Secrets and variables → Actions → Variables, create `API_BASE_URL` with the Railway domain, without `/docs`.
2. Open Actions → Build Android APK → Run workflow.
3. Download `photosync-android-apks` from Artifacts.
4. Install `app-debug.apk` for testing. Use `app-release.apk` only for direct testing; Play Store publishing needs your own signing key.

The workflow creates the native `mobile/android` directory using the installed stable Flutter SDK, adds required media permissions, analyzes and tests the project, and then builds both APKs.

## Local backend

```bash
cd backend
cp .env.example .env
docker compose up --build
```

## Environment contract

The Flutter app reads the server address at compile time:

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.example.com
```

## Important production boundaries

The repository is deployable and its build pipelines are complete. Model-dependent features such as semantic image embeddings, face clustering, and full OCR require licensed on-device model binaries. The app deliberately keeps those integrations disabled rather than shipping unknown or unlicensed weights. Messaging apps do not expose reliable public contact-to-media mappings, so contact assignment must remain user-confirmed. Release distribution also requires the owner's Android signing key.

## Local smart albums and people matching

The mobile app includes four on-device features requested for the deployment build:

- Duplicate and near-duplicate detection using a 64-bit perceptual difference hash.
- Date albums grouped by month and year.
- Location albums grouped from the GPS coordinates already stored in photo metadata.
- Memories with “On this day” and yearly collections.
- Person albums created from one user-selected reference image and a user-selected 1–20 year scan window.

Person albums use Google ML Kit only to detect and crop faces. Matching is then performed locally with a normalized visual face descriptor. No reference image, face crop, descriptor, or photo is uploaded to the PhotoSync backend. This is intended as convenient personal gallery matching, not identity verification or security-grade biometric recognition.

## Added local smart features

The main project includes duplicate detection, GPS-based location albums, month/year albums, on-this-day and yearly memories, and user-created person albums. A person album uses a selected reference image, a user-selected history window, on-device ML Kit face detection and local visual matching. It never uploads the reference face or scan results. See `FEATURES.md` for the complete project inventory.
