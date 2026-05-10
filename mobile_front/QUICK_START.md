# Quick Start Guide

## Prerequisites

Before running the Flutter app, ensure you have:

1. **Flutter SDK** installed (3.9.0 or higher)
   ```bash
   flutter --version
   ```

2. **Backend Server** running on `http://localhost:8080`
   - Navigate to `Pfe_Backend` directory
   - Run the Spring Boot application

3. **Android Studio** or **Xcode** (for mobile development)
   - Android Studio for Android development
   - Xcode for iOS development (macOS only)

## Installation Steps

### 1. Navigate to Project Directory
```bash
cd mobile_front
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Verify Installation
```bash
flutter doctor
```
Fix any issues reported by Flutter Doctor.

### 4. Run the App

**For Android Emulator:**
```bash
flutter run
```

**For iOS Simulator (macOS only):**
```bash
flutter run -d ios
```

**For Chrome (Web):**
```bash
flutter run -d chrome
```

**For Windows Desktop:**
```bash
flutter run -d windows
```

## Configuration

### Backend URL Configuration

The default backend URL is `http://localhost:8080/api`.

**For Android Emulator:**
Android emulators cannot access `localhost` directly. Update the base URL in `lib/services/api_client.dart`:

```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

**For iOS Simulator:**
iOS simulators can access localhost directly:
```dart
static const String baseUrl = 'http://localhost:8080/api';
```

**For Physical Devices:**
Use your computer's IP address:
```dart
static const String baseUrl = 'http://192.168.1.XXX:8080/api';
```

To find your IP address:
- **Windows:** `ipconfig`
- **macOS/Linux:** `ifconfig` or `ip addr`

## Testing the App

### 1. Start Backend Server
```bash
cd Pfe_Backend
./mvnw spring-boot:run
# or
mvn spring-boot:run
```

### 2. Verify Backend is Running
Open browser and navigate to:
```
http://localhost:8080/api/categories
```
You should see a JSON response with categories.

### 3. Run Flutter App
```bash
cd mobile_front
flutter run
```

### 4. Test Login Flow

**Option 1: Create a Student Account**
1. Click "Create Student Account"
2. Fill in basic information
3. Select at least 3 categories
4. Choose skill level
5. Submit registration
6. Login with credentials

**Option 2: Apply as Instructor**
1. Click "Apply as Instructor"
2. Fill in all required fields
3. Upload certification file
4. Submit application
5. Wait for admin approval (check backend logs)

**Option 3: Use Existing Credentials**
If you have existing test accounts in the database:
```
Username: testuser
Password: password123
```

## Common Issues & Solutions

### Issue 1: Cannot Connect to Backend
**Error:** `Network error: Failed to connect`

**Solutions:**
- Verify backend is running: `curl http://localhost:8080/api/categories`
- Check firewall settings
- For Android emulator, use `http://10.0.2.2:8080/api`
- For physical device, use computer's IP address

### Issue 2: File Picker Not Working
**Error:** File picker crashes or doesn't open

**Solutions:**
- **Android:** Add permissions to `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
  ```

- **iOS:** Add to `ios/Runner/Info.plist`:
  ```xml
  <key>NSPhotoLibraryUsageDescription</key>
  <string>We need access to your photo library to upload certification</string>
  <key>NSCameraUsageDescription</key>
  <string>We need access to your camera to take photos</string>
  ```

### Issue 3: Secure Storage Issues
**Error:** Token not persisting after app restart

**Solutions:**
- Clear app data and reinstall
- Check platform-specific setup for `flutter_secure_storage`
- For Android, ensure minimum SDK version is 18

### Issue 4: Categories Not Loading
**Error:** "Failed to load categories"

**Solutions:**
- Verify backend `/api/categories` endpoint is working
- Check network connectivity
- Review backend logs for errors
- Ensure categories exist in database

## Development Tips

### Hot Reload
While the app is running, press:
- `r` - Hot reload (fast)
- `R` - Hot restart (slower, full restart)
- `q` - Quit

### Debug Mode
Run with verbose logging:
```bash
flutter run -v
```

### View Logs
```bash
flutter logs
```

### Clear Build Cache
If you encounter build issues:
```bash
flutter clean
flutter pub get
flutter run
```

## Project Structure Overview

```
mobile_front/
├── lib/
│   ├── models/           # Data models
│   ├── providers/        # State management
│   ├── router/           # Navigation
│   ├── screens/          # UI screens
│   ├── services/         # API services
│   └── main.dart         # Entry point
├── assets/
│   └── images/           # Images and icons
└── pubspec.yaml          # Dependencies
```

## Next Steps

After successfully running the app:

1. **Test All Flows:**
   - Login with different roles
   - Student registration
   - Instructor application
   - Logout functionality

2. **Customize UI:**
   - Update colors in `lib/main.dart` theme
   - Modify logo in `assets/images/`
   - Adjust layouts in screen files

3. **Add Features:**
   - Implement home screen functionality
   - Add profile management
   - Integrate course browsing
   - Add payment integration

4. **Deploy:**
   - Build release APK for Android
   - Build IPA for iOS
   - Configure production backend URL

## Build for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (macOS only)
```bash
flutter build ios --release
```

## Support

For issues or questions:
1. Check the main README: `README_AUTH.md`
2. Review API documentation: `API_REFERENCE.md`
3. Check Flutter documentation: https://flutter.dev/docs
4. Review backend logs for API errors

## Useful Commands

```bash
# Check Flutter version
flutter --version

# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Build for release
flutter build apk --release

# Analyze code
flutter analyze

# Run tests
flutter test

# Update dependencies
flutter pub upgrade

# Clean build
flutter clean
```

Happy coding! 🚀
