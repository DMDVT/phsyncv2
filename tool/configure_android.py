from pathlib import Path
import re

MANIFEST_PATH = Path(
    "mobile/android/app/src/main/AndroidManifest.xml"
)

manifest_text = MANIFEST_PATH.read_text(encoding="utf-8")

permissions = """
    <uses-permission android:name="android.permission.INTERNET" />

    <!-- Android 13+ photo and video access -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

    <!-- Android 12 and older photo/video access -->
    <uses-permission
        android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />

    <!-- Required for unredacted EXIF/GPS metadata -->
    <uses-permission
        android:name="android.permission.ACCESS_MEDIA_LOCATION" />
"""

manifest_tag = (
    '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
)

if "android.permission.READ_MEDIA_IMAGES" not in manifest_text:
    manifest_text = manifest_text.replace(
        manifest_tag,
        f"{manifest_tag}\n{permissions}",
        1,
    )

MANIFEST_PATH.write_text(
    manifest_text,
    encoding="utf-8",
)

gradle_kts = Path("mobile/android/app/build.gradle.kts")

if gradle_kts.exists():
    gradle_text = gradle_kts.read_text(encoding="utf-8")

    gradle_text = re.sub(
        r"compileSdk\s*=\s*flutter\.compileSdkVersion",
        "compileSdk = 36",
        gradle_text,
    )

    gradle_text = re.sub(
        r"compileSdk\s*=\s*\d+",
        "compileSdk = 36",
        gradle_text,
    )

    gradle_text = re.sub(
        r"minSdk\s*=\s*flutter\.minSdkVersion",
        "minSdk = 21",
        gradle_text,
    )

    gradle_text = re.sub(
        r"targetSdk\s*=\s*flutter\.targetSdkVersion",
        "targetSdk = 36",
        gradle_text,
    )

    gradle_kts.write_text(
        gradle_text,
        encoding="utf-8",
    )

legacy_gradle = Path("mobile/android/app/build.gradle")

if legacy_gradle.exists():
    gradle_text = legacy_gradle.read_text(encoding="utf-8")

    gradle_text = re.sub(
        r"compileSdkVersion\s+flutter\.compileSdkVersion",
        "compileSdkVersion 36",
        gradle_text,
    )

    gradle_text = re.sub(
        r"compileSdkVersion\s+\d+",
        "compileSdkVersion 36",
        gradle_text,
    )

    gradle_text = re.sub(
        r"minSdkVersion\s+flutter\.minSdkVersion",
        "minSdkVersion 21",
        gradle_text,
    )

    gradle_text = re.sub(
        r"targetSdkVersion\s+flutter\.targetSdkVersion",
        "targetSdkVersion 36",
        gradle_text,
    )

    legacy_gradle.write_text(
        gradle_text,
        encoding="utf-8",
    )

print("Android permissions and SDK settings configured.")
