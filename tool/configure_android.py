from pathlib import Path
import re

manifest = Path('mobile/android/app/src/main/AndroidManifest.xml')
text = manifest.read_text()
permissions = '''<uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    '''
if 'android.permission.READ_MEDIA_IMAGES' not in text:
    text = text.replace(
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">',
        '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n    ' + permissions,
    )
manifest.write_text(text)

kts = Path('mobile/android/app/build.gradle.kts')
if kts.exists():
    gradle = kts.read_text()
    gradle = re.sub(r'compileSdk\s*=\s*flutter\.compileSdkVersion', 'compileSdk = 35', gradle)
    gradle = re.sub(r'minSdk\s*=\s*flutter\.minSdkVersion', 'minSdk = 21', gradle)
    gradle = re.sub(r'targetSdk\s*=\s*flutter\.targetSdkVersion', 'targetSdk = 35', gradle)
    kts.write_text(gradle)

legacy = Path('mobile/android/app/build.gradle')
if legacy.exists():
    gradle = legacy.read_text()
    gradle = re.sub(r'compileSdkVersion\s+flutter\.compileSdkVersion', 'compileSdkVersion 35', gradle)
    gradle = re.sub(r'minSdkVersion\s+flutter\.minSdkVersion', 'minSdkVersion 21', gradle)
    gradle = re.sub(r'targetSdkVersion\s+flutter\.targetSdkVersion', 'targetSdkVersion 35', gradle)
    legacy.write_text(gradle)
