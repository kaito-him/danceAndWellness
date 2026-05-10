@echo off
echo ========================================
echo Finding Your Computer's IP Address
echo ========================================
echo.

ipconfig | findstr /i "IPv4"

echo.
echo ========================================
echo Instructions:
echo ========================================
echo 1. Look for the IPv4 Address above (e.g., 192.168.1.100)
echo 2. Open: mobile_front\lib\services\api_client.dart
echo 3. Change the baseUrl to: http://YOUR_IP:8080/api
echo 4. Hot restart your Flutter app (press R)
echo ========================================
echo.
pause
