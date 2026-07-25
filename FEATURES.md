# PhotoSync feature inventory

PhotoSync is a Flutter mobile gallery with a FastAPI social backend. Media browsing and smart albums are local-first; media is sent to the backend only when the user explicitly shares it.

## Mobile gallery and organization

- Device photo and video permission flow
- Device media scan with local thumbnails
- Main photo grid and full-screen viewer
- Video playback
- Device album discovery
- Favorites, archive, hidden/vault foundations
- Search by filename and local tags
- Light and dark themes
- Storage analytics and large-file review

## Smart albums and memories

- Duplicate and near-duplicate detection using on-device perceptual difference hashes
- Duplicate groups that open as normal photo collections
- Location albums built from GPS metadata, grouped into nearby coordinate regions
- Date albums grouped by month and year
- “On this day” memories from earlier years
- Year-by-year memory albums

## Person reference albums

- User selects a clear reference photo
- User names the person album
- User chooses a scan range from 1 to 20 past years
- Photo creation metadata limits the scan to that date range
- Google ML Kit detects faces on-device
- Local visual face descriptors compare detected faces with the reference image
- Matching asset IDs are saved locally as a reusable person album
- Reference images are copied into private app document storage
- Saved person albums can be opened or deleted
- No face image or face descriptor is uploaded to the server

Identity matching is an on-device visual similarity feature. Ordinary photo metadata does not contain a person’s identity, so metadata is used for dates and GPS while detected facial appearance is used for matching.

## Editing and media tools

- Photo-viewing and editing integration points
- Image compression service and quality controls
- Video-processing integration points
- Vault PIN and local-authentication foundations
- Received-media and storage-management foundations

## Accounts and social backend

- Email/password registration and login
- JWT access and refresh token foundations
- User profiles and username search
- Friend requests, accept, decline, remove and block
- Friends-only sharing rules
- Temporary photo/video relay uploads
- Pending shares, downloads and delivery confirmation
- Automatic expiry cleanup for relay files
- Share history
- In-app notifications
- Collaborative shared albums with viewer/editor/admin permissions
- Temporary, revocable and password-capable share links
- Device registration and sync-preference APIs
- Cross-device metadata-sync APIs

## Deployment and automation

- FastAPI Docker image
- PostgreSQL and Redis Docker Compose configuration
- Celery cleanup worker
- Railway configuration and Railway-compatible start script
- Environment templates
- GitHub Actions backend tests and Docker build
- GitHub Actions Android debug/release APK build
- Codemagic Android workflow
- Android project generation during CI
- Android media and internet permission configuration
- API base URL supplied with `--dart-define`
