# Fixes Applied to Resolve Build Issues

## Issues Encountered and Fixed

### 1. File Picker Compatibility Issue
**Error:** `file_picker:6.2.1` had v1 embedding issues causing compilation errors

**Fix:**
- Updated `file_picker` from `^6.1.1` to `^8.0.0` in `pubspec.yaml`
- This version supports the v2 embedding properly

### 2. Android SDK Version Mismatch
**Error:** Plugins required Android SDK 36 but project was compiled against SDK 34

**Fix:**
- Updated `compileSdk` from 34 to 36 in `android/app/build.gradle`
- Updated `targetSdk` from 34 to 36
- Set `minSdk` to 21 (Android 5.0)
- Changed Java version from 11 to 17

### 3. Build Configuration File Type
**Error:** Flutter kept auto-upgrading `build.gradle.kts` (Kotlin) and reverting changes

**Fix:**
- Converted from Kotlin DSL (`build.gradle.kts`) to Groovy DSL (`build.gradle`)
- Groovy version is more stable and doesn't get auto-upgraded

### 4. XML Entity Error in AndroidManifest
**Error:** `The entity name must immediately follow the '&' in the entity reference`

**Fix:**
- Changed app label from `"Dance & Wellness"` to `"Dance &amp; Wellness"`
- XML requires `&` to be escaped as `&amp;`

### 5. Android Permissions
**Added permissions for:**
- `INTERNET` - Network access for API calls
- `READ_EXTERNAL_STORAGE` - File picker access
- `WRITE_EXTERNAL_STORAGE` - File picker access
- `READ_MEDIA_IMAGES` - Image picker (Android 13+)
- `READ_MEDIA_VIDEO` - Video picker (Android 13+)
- `READ_MEDIA_AUDIO` - Audio picker (Android 13+)

## Final Configuration

### pubspec.yaml
```yaml
dependencies:
  provider: ^6.1.1
  dio: ^5.4.0
  go_router: ^13.0.0
  flutter_secure_storage: ^9.0.0
  file_picker: ^8.0.0  # Updated
  image_picker: ^1.1.2  # Updated
  http_parser: ^4.0.2
```

### android/app/build.gradle
```groovy
android {
    namespace = "com.example.mobile_front"
    compileSdk = 36  # Updated
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17  # Updated
        targetCompatibility = JavaVersion.VERSION_17  # Updated
    }
    
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17  # Updated
    }
    
    defaultConfig {
        applicationId = "com.example.mobile_front"
        minSdk = 21  # Set explicitly
        targetSdk = 36  # Updated
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

### AndroidManifest.xml
```xml
<application
    android:label="Dance &amp; Wellness"  <!-- Fixed -->
    ...>
```

## How to Run

1. **Clean the project:**
   ```bash
   flutter clean
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on device:**
   ```bash
   flutter run
   ```

## Backend Configuration

For Android physical devices or emulators, update the API base URL in `lib/services/api_client.dart`:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

**For Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8080/api';
```

Find your IP:
- Windows: `ipconfig`
- Look for "IPv4 Address" under your active network adapter

## Troubleshooting

### If build still fails:
1. Close Android Studio / VS Code
2. Delete `android/.gradle` folder
3. Delete `build` folder
4. Run `flutter clean`
5. Run `flutter pub get`
6. Try again

### If file locking errors occur:
- Close all IDEs and terminals
- Wait a few seconds
- Try running again

### If backend connection fails:
- Ensure backend is running on `http://localhost:8080`
- Check firewall settings
- Verify the correct IP address is used for physical devices
- Test backend: `curl http://localhost:8080/api/categories`

## Status

✅ All build configuration issues resolved
✅ Dependencies updated to compatible versions
✅ Android manifest fixed
✅ Permissions added
✅ Ready to run on Android devices

The app should now build and run successfully!
