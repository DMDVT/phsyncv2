# Requested Feature Status

## Implemented

- Duplicate and near-duplicate photo groups
- GPS metadata location albums
- Month/year date albums
- On-this-day memories
- Yearly memory albums
- Reference-photo person album creation
- User-selectable scan window from 1 to 20 past years
- On-device face detection and local reference similarity matching
- Persistent person album records using local app preferences
- No face or photo upload to the backend

## Expected real-device behavior

The first person scan may take several minutes on a large library because each candidate photo is opened and processed locally. Android may pause a scan if the operating system terminates the app. Keep PhotoSync open during the initial scan.

Face matching is designed for personal photo organization. Lighting, age changes, side profiles, masks, very small faces, and low-resolution photos can cause missed matches or false matches. It must not be used for authentication or identity verification.
