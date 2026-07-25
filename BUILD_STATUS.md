# Build status

This repository is configured as a deployable Flutter/FastAPI monorepo.

Validated in the generation environment:

- All Python backend and tooling files compile.
- All YAML and JSON configuration files parse.
- GitHub Actions workflows are present for backend CI and Android APK builds.
- Codemagic and Railway configuration files are present.
- The Android project is generated during CI and configured with media and internet permissions.
- Duplicate, location, date, memory and reference-person album features are integrated into the main Flutter navigation.

Final deployment validation still happens through the included GitHub Actions Android workflow because this packaging environment does not include the Flutter SDK or Android SDK. A successful green workflow run produces the installable APK artifacts.
