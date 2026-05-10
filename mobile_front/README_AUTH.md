# Dance & Wellness - Flutter Authentication System

A complete Flutter authentication system for the Dance & Wellness platform with JWT-based authentication, role-based routing, and multi-step registration flows.

## Features

✅ **Login System**
- Username/password authentication
- JWT token management with secure storage
- Role-based routing (Student, Instructor, Admin)
- Error handling for inactive/pending accounts

✅ **Student Registration**
- Two-step registration flow
- Basic info collection (username, email, password)
- Category selection (minimum 3 required)
- Skill level selection (Beginner, Intermediate, Advanced)

✅ **Instructor Application**
- Comprehensive application form
- Professional information collection
- Certification file upload (PDF/Image)
- Multipart form data submission

✅ **Role-Based Home Screens**
- Student Dashboard
- Instructor Dashboard
- Admin Dashboard
- Logout functionality

## Project Structure

```
mobile_front/
├── lib/
│   ├── models/                          # Data models
│   │   ├── category.dart
│   │   ├── instructor_application_request.dart
│   │   ├── login_request.dart
│   │   ├── login_response.dart
│   │   ├── skill_level.dart
│   │   ├── student_registration_request.dart
│   │   └── user_role.dart
│   │
│   ├── providers/                       # State management (Provider)
│   │   ├── auth_provider.dart
│   │   └── category_provider.dart
│   │
│   ├── router/                          # Navigation (go_router)
│   │   └── app_router.dart
│   │
│   ├── screens/                         # UI screens
│   │   ├── admin_home_screen.dart
│   │   ├── instructor_application_screen.dart
│   │   ├── instructor_home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── splash_screen.dart
│   │   ├── student_home_screen.dart
│   │   └── student_registration_screen.dart
│   │
│   ├── services/                        # API services
│   │   ├── api_client.dart
│   │   ├── auth_service.dart
│   │   └── category_service.dart
│   │
│   └── main.dart                        # App entry point
│
├── assets/
│   └── images/
│       └── Dicone.png                   # App logo
│
└── pubspec.yaml                         # Dependencies
```

## Dependencies

```yaml
dependencies:
  provider: ^6.1.1              # State management
  dio: ^5.4.0                   # HTTP client
  go_router: ^13.0.0            # Routing
  flutter_secure_storage: ^9.0.0 # Secure token storage
  file_picker: ^6.1.1           # File selection
  image_picker: ^1.0.7          # Image selection
  http_parser: ^4.0.2           # HTTP parsing
```

## Backend API Integration

### Base URL
```
http://localhost:8080/api
```

### Endpoints

#### 1. Login
```
POST /api/auth/login
Content-Type: application/json

Request:
{
  "username": "user123",
  "password": "password123"
}

Response (Success):
{
  "success": true,
  "role": "STUDENT",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Login successful",
  "userId": "64a1b2c3d4e5f6"
}
```

#### 2. Student Registration
```
POST /api/auth/register/student
Content-Type: application/json

Request:
{
  "username": "newstudent",
  "email": "student@example.com",
  "password": "password123",
  "categoryIds": ["cat1", "cat2", "cat3"],
  "skillLevel": "BEGINNER"
}

Response: 201 Created
"Account created successfully."
```

#### 3. Instructor Application
```
POST /api/auth/register/instructor
Content-Type: multipart/form-data

Fields:
- data: JSON string with instructor info
- certFile: File upload (PDF/Image)

Response: 201 Created
"Application submitted. Check your e-mail for confirmation."
```

#### 4. Get Categories
```
GET /api/categories

Response:
[
  { "id": "cat1", "name": "Ballet", "icon": "..." },
  { "id": "cat2", "name": "Yoga", "icon": "..." }
]
```

## Setup Instructions

### 1. Prerequisites
- Flutter SDK (3.9.0 or higher)
- Dart SDK
- Android Studio / Xcode (for mobile development)
- Backend server running on `http://localhost:8080`

### 2. Installation

```bash
# Navigate to project directory
cd mobile_front

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### 3. Configuration

If your backend is running on a different URL, update the base URL in:
```dart
// lib/services/api_client.dart
static const String baseUrl = 'http://YOUR_BACKEND_URL/api';
```

For Android emulator to access localhost:
```dart
static const String baseUrl = 'http://10.0.2.2:8080/api';
```

For iOS simulator:
```dart
static const String baseUrl = 'http://localhost:8080/api';
```

## Key Features Explained

### 1. Secure Token Storage
JWT tokens are stored securely using `flutter_secure_storage`:
```dart
await _storage.write(key: 'jwt_token', value: token);
```

### 2. Automatic Token Injection
The API client automatically attaches JWT tokens to requests:
```dart
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'jwt_token');
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ),
);
```

### 3. Role-Based Routing
GoRouter automatically redirects users based on their role:
```dart
redirect: (context, state) {
  if (isAuthenticated && role != null) {
    switch (role) {
      case UserRole.student:
        return '/student/home';
      case UserRole.instructor:
        return '/instructor/home';
      case UserRole.admin:
        return '/admin/home';
    }
  }
  return null;
}
```

### 4. Multi-Step Registration
Student registration uses a PageView for a smooth multi-step experience:
- Step 1: Basic information (username, email, password)
- Step 2: Onboarding (category selection, skill level)

### 5. File Upload
Instructor application supports file uploads using multipart/form-data:
```dart
final formData = FormData.fromMap({
  'data': jsonEncode(request.toJson()),
  'certFile': await MultipartFile.fromFile(certFilePath),
});
```

## Error Handling

The app handles various error scenarios:

1. **Network Errors**: Shows user-friendly error messages
2. **Validation Errors**: Form validation with inline error messages
3. **Account Status**: Special handling for PENDING/INACTIVE accounts
4. **API Errors**: Displays backend error messages to users

## UI/UX Features

- **Material 3 Design**: Modern, clean interface
- **Loading Indicators**: Shows progress during API calls
- **Form Validation**: Real-time validation with error messages
- **Responsive Layout**: Works on various screen sizes
- **Password Visibility Toggle**: User-friendly password fields
- **Progress Indicators**: Visual feedback for multi-step flows

## Testing

### Manual Testing Checklist

- [ ] Login with valid credentials
- [ ] Login with invalid credentials
- [ ] Login with pending account
- [ ] Login with inactive account
- [ ] Student registration (complete flow)
- [ ] Student registration (validation errors)
- [ ] Instructor application (complete flow)
- [ ] Instructor application (file upload)
- [ ] Role-based routing (Student)
- [ ] Role-based routing (Instructor)
- [ ] Role-based routing (Admin)
- [ ] Logout functionality
- [ ] Token persistence (app restart)

## Troubleshooting

### Common Issues

1. **Cannot connect to backend**
   - Ensure backend is running on `http://localhost:8080`
   - For Android emulator, use `http://10.0.2.2:8080`
   - Check firewall settings

2. **File picker not working**
   - Ensure proper permissions in AndroidManifest.xml / Info.plist
   - Check platform-specific setup for file_picker

3. **Secure storage issues**
   - On Android, ensure minimum SDK version is 18
   - On iOS, ensure proper keychain access

4. **Token not persisting**
   - Check flutter_secure_storage initialization
   - Verify platform-specific setup

## Future Enhancements

- [ ] Biometric authentication
- [ ] Social login (Google, Facebook)
- [ ] Password reset functionality
- [ ] Email verification
- [ ] Profile picture upload
- [ ] Remember me functionality
- [ ] Offline mode support
- [ ] Push notifications

## License

This project is part of the Dance & Wellness platform.

## Support

For issues or questions, please contact the development team.
