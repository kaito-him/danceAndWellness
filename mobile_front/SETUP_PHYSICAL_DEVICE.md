# Setup for Physical Android Device

## Problem
You're getting a connection timeout because the app is trying to connect to `http://10.0.2.2:8080/api`, which only works for Android emulators, not physical devices.

## Solution: Find Your Computer's IP Address

### Step 1: Find Your IP Address

**On Windows:**
```bash
ipconfig
```

Look for the section that says "Wireless LAN adapter Wi-Fi" or "Ethernet adapter", then find:
```
IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**On Mac/Linux:**
```bash
ifconfig
# or
ip addr show
```

Look for `inet` followed by an IP like `192.168.1.100`

### Step 2: Update the API URL

Open `mobile_front/lib/services/api_client.dart` and change:

**FROM:**
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

**TO:** (replace with YOUR IP)
```dart
static const String baseUrl = 'http://192.168.1.100:8080/api';
```

### Step 3: Verify Backend is Accessible

Test from your phone's browser or another device on the same network:
```
http://YOUR_IP:8080/api/categories
```

You should see JSON data with categories.

### Step 4: Hot Restart the App

In your terminal where `flutter run` is active, press:
```
R  (capital R)
```

Or stop and restart:
```bash
flutter run
```

### Step 5: Try Login Again

The logs should now show:
```
🔵 API URL: http://YOUR_IP:8080/api/auth/login
🟢 Login response status: 200
```

## Checklist

- [ ] Found your computer's IP address
- [ ] Updated `lib/services/api_client.dart` with your IP
- [ ] Backend is running (`mvn spring-boot:run`)
- [ ] Phone and computer on SAME WiFi network
- [ ] Can access `http://YOUR_IP:8080/api/categories` from phone browser
- [ ] Hot restarted Flutter app (press R)
- [ ] Firewall allows connections on port 8080

## Still Not Working?

### Check Firewall (Windows)

1. Open "Windows Defender Firewall"
2. Click "Allow an app or feature through Windows Defender Firewall"
3. Click "Change settings"
4. Find "Java(TM) Platform SE binary" or your IDE
5. Check BOTH "Private" and "Public" boxes
6. Click OK

### Test Backend Accessibility

From your phone's browser, visit:
```
http://YOUR_IP:8080/api/categories
```

If this doesn't work, the problem is network/firewall, not the Flutter app.

### Alternative: Use Emulator

If you can't get the physical device working, use an Android emulator instead:

1. Open Android Studio
2. Tools > Device Manager
3. Create a new virtual device
4. Run the app on the emulator
5. Use `http://10.0.2.2:8080/api` (no IP change needed)

## Quick Reference

| Setup | API Base URL |
|-------|--------------|
| Android Emulator | `http://10.0.2.2:8080/api` |
| Physical Device | `http://YOUR_IP:8080/api` |
| iOS Simulator | `http://localhost:8080/api` |

## Example

If your computer's IP is `192.168.1.105`, update the code to:

```dart
class ApiClient {
  static const String baseUrl = 'http://192.168.1.105:8080/api';
  // ...
}
```

Then hot restart (press R) and try logging in again!
