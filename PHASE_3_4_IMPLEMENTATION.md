# Phase 3–4 implementation

## Phase 3
Implemented backend foundations for friends, requests, blocking, temporary media relay, pending delivery, confirmation/deletion, share history, notifications, collaborative album membership, and expiring share links. Flutter includes API clients and Sharing/Notifications screens.

## Phase 4
Implemented local foundations for WebP photo compression and a platform hook for AV1/H.265 video encoding, secure PIN vault access, storage analytics, duplicate candidates, messaging-album discovery, manual/time-window contact matching, memories, expanded Drift tables, and metadata-sync persistence.

## Important production boundaries
- WhatsApp and other apps do not expose a reliable public API mapping every media file to a chat contact. The implementation therefore uses manual assignment and explicitly low-confidence timestamp suggestions rather than claiming exact matching.
- AV1 encoding requires native FFmpeg/platform packaging and real-device benchmarks. The video service currently preserves the original through a safe copy and marks the production integration point.
- Vault media encryption and biometric unlock should be implemented in native platform storage before release; the current secure-storage PIN gate is an application foundation.
- Mobile ML binary models are not redistributed. Add licensed `.tflite`/`.onnx` assets under `assets/ml_models` and connect them through `ai_service.dart`.
