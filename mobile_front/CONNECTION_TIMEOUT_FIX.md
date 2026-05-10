# ⚠️ CONNECTION TIMEOUT - QUICK FIX

## What's Happening

Your logs show:
```
🔴 DioException during login: DioExceptionType.connectionTimeout
🔴 Error message: The request connection took longer than 0:00:30.000000
```

This means the app **cannot reach** the backend server.

## Why This Happens

You're using a **physical Android device** (RMX3710), but the app is configured for an **emulator**.

The URL `http://10.0.2.2:8080/api` only works for Android emulators, not physical devices.

## 🔧 QUICK FIX (3 Steps)

### Step 1: Find Your Computer's IP

**Windows:**
```bash
ipconfig
```

Look for:
```
Wireless LAN adapter Wi-Fi:
   IPv4 Address. . . . . . . . . . . : 192.168.1.100
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
```

### Step 2: Update the Code

Open: `mobile_front/lib/services/api_client.dart`

**Change line 15 from:**
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

**To:** (use YOUR IP)
```dart
static const String baseUrl = 'http://192.168.1.100:8080/api';
```

### Step 3: Hot Restart

In your terminal where `flutter run` is active:
```
Press: R (capital R)
```

Or restart completely:
```bash
flutter run
```

## ✅ Verify It Works

After restarting, try logging in. You should see:
```
🔵 API URL: http://192.168.1.100:8080/api/auth/login
🟢 Login response status: 200
🟢 Login response data: {success: true, ...}
```

## 🔍 Troubleshooting

### Can't Find IP?

Run the helper script:
```bash
cd mobile_front
find_ip.bat
```

### Still Timeout?

**Check 1: Backend Running**
```bash
cd Pfe_Backend
mvn spring-boot:run
```

**Check 2: Same WiFi Network**
- Your phone must be on the SAME WiFi as your computer
- Not mobile data, not different WiFi

**Check 3: Test from Phone Browser**

Open your phone's browser and visit:
```
http://YOUR_IP:8080/api/categories
```

If this doesn't work, it's a network/firewall issue.

**Check 4: Windows Firewall**

1. Search "Windows Defender Firewall"
2. Click "Allow an app through firewall"
3. Find "Java" or your IDE
4. Enable both Private and Public
5. Click OK

### Alternative: Use Emulator

If physical device is too complicated:

1. Open Android Studio
2. Tools > Device Manager  
3. Create virtual device
4. Run app on emulator
5. Keep `http://10.0.2.2:8080/api` (no change needed)

## 📝 Example

**My computer's IP:** `192.168.1.105`

**Update code to:**
```dart
class ApiClient {
  static const String baseUrl = 'http://192.168.1.105:8080/api';
  // ...
}
```

**Hot restart:** Press `R`

**Try login:** Should work! ✅

## 🎯 Quick Checklist

- [ ] Found my computer's IP address
- [ ] Updated `lib/services/api_client.dart` with MY IP
- [ ] Backend is running (port 8080)
- [ ] Phone and computer on SAME WiFi
- [ ] Hot restarted app (pressed R)
- [ ] Tried logging in

## Need More Help?

See detailed guides:
- `SETUP_PHYSICAL_DEVICE.md` - Full setup guide
- `TROUBLESHOOTING.md` - Common issues
- `QUICK_START.md` - General setup

---

**TL;DR:** Change `10.0.2.2` to your computer's actual IP address in `api_client.dart`, then press R to restart!
