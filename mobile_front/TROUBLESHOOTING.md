# Troubleshooting Guide

## Issue: Login Button Does Nothing / NullPointerException

### Symptoms
- Clicking login button shows no response
- Console shows: `java.lang.NullPointerException`
- No error message displayed to user

### Root Causes & Solutions

#### 1. Backend Not Running
**Check:**
```bash
# Test if backend is accessible
curl http://localhost:8080/api/categories
```

**Solution:**
```bash
cd Pfe_Backend
./mvnw spring-boot:run
# or
mvn spring-boot:run
```

#### 2. Wrong API URL for Android Device

**Problem:** Android devices/emulators cannot access `localhost` directly.

**Solution:** Update `lib/services/api_client.dart`:

**For Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

**For Physical Android Device:**
1. Find your computer's IP address:
   ```bash
   # Windows
   ipconfig
   # Look for IPv4 Address (e.g., 192.168.1.100)
   
   # Mac/Linux
   ifconfig
   # or
   ip addr
   ```

2. Update the URL:
   ```dart
   static const String baseUrl = 'http://192.168.1.100:8080/api';
   ```

3. **Important:** Ensure your phone and computer are on the same WiFi network!

#### 3. Firewall Blocking Connection

**Windows:**
1. Open Windows Defender Firewall
2. Click "Allow an app through firewall"
3. Find Java or your IDE
4. Enable both Private and Public networks

**Alternative:** Temporarily disable firewall to test

#### 4. Backend CORS Configuration

If you see CORS errors, update your Spring Boot backend:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("*")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
```

## Debugging Steps

### 1. Check Flutter Logs

Run the app and watch the console output:
```bash
flutter run
```

Look for these log messages:
- 🔵 Blue = Info/Debug
- 🟢 Green = Success
- 🔴 Red = Error

### 2. Test Network Connectivity

Add this to your login screen temporarily:

```dart
import '../utils/network_test.dart';

// In your button or initState:
NetworkTest.testConnection();
```

### 3. Check Backend Logs

Watch your Spring Boot console for incoming requests:
```
2026-05-07 12:00:00.000  INFO --- [nio-8080-exec-1] c.e.d.controller.AuthController : Login attempt for user: testuser
```

If you don't see this, the request isn't reaching the backend.

### 4. Verify Backend Endpoints

Test each endpoint manually:

```bash
# Test categories endpoint
curl http://localhost:8080/api/categories

# Test login endpoint
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

## Common Error Messages

### "Network error: Failed host lookup"
- **Cause:** Cannot resolve hostname
- **Solution:** Check API URL, ensure backend is running

### "Network error: Connection refused"
- **Cause:** Backend not running or wrong port
- **Solution:** Start backend, verify port 8080

### "Network error: Connection timed out"
- **Cause:** Firewall blocking or wrong IP
- **Solution:** Check firewall, verify IP address

### "SocketException: OS Error: Connection refused"
- **Cause:** Backend not accessible from device
- **Solution:** Use correct IP (10.0.2.2 for emulator, actual IP for device)

## Quick Fix Checklist

- [ ] Backend is running (`http://localhost:8080`)
- [ ] Can access backend from browser
- [ ] API URL is correct for your device type
- [ ] Phone and computer on same WiFi (for physical device)
- [ ] Firewall allows connections
- [ ] No CORS errors in backend logs
- [ ] Flutter app rebuilt after code changes (`flutter run`)

## Testing with Different Configurations

### Test 1: Emulator
```dart
// lib/services/api_client.dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

### Test 2: Physical Device (Same WiFi)
```dart
// lib/services/api_client.dart
static const String baseUrl = 'http://YOUR_COMPUTER_IP:8080/api';
```

### Test 3: iOS Simulator
```dart
// lib/services/api_client.dart
static const String baseUrl = 'http://localhost:8080/api';
```

## Still Not Working?

### Enable Verbose Logging

1. Check all console output when clicking login
2. Look for the 🔵🟢🔴 emoji logs
3. Note the exact error message
4. Check if request reaches backend

### Create Test User

Ensure you have a test user in the database:

```sql
-- Check if user exists
SELECT * FROM users WHERE username = 'testuser';

-- Create test user if needed (adjust based on your schema)
INSERT INTO users (username, email, password, role, status) 
VALUES ('testuser', 'test@example.com', 'hashed_password', 'STUDENT', 'ACTIVE');
```

### Network Debugging

Use Android Studio's Network Profiler:
1. Run app in debug mode
2. Open Android Studio
3. View > Tool Windows > Profiler
4. Select Network tab
5. Try logging in
6. Check if HTTP request is made

## Contact Information

If none of these solutions work:
1. Copy the full error log from Flutter console
2. Copy the backend console output
3. Note your configuration (emulator/device, IP address, etc.)
4. Share this information for further assistance

## Quick Reference

| Device Type | API Base URL |
|-------------|--------------|
| Android Emulator | `http://10.0.2.2:8080/api` |
| iOS Simulator | `http://localhost:8080/api` |
| Physical Device | `http://YOUR_IP:8080/api` |
| Web Browser | `http://localhost:8080/api` |

Remember: After changing the API URL, always hot restart the app (press 'R' in terminal or restart from IDE).
