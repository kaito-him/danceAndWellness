# API Reference Guide

## Base URL
```
http://localhost:8080/api
```

## Authentication Endpoints

### 1. Login

**Endpoint:** `POST /api/auth/login`

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "username": "string",
  "password": "string"
}
```

**Success Response (200 OK):**
```json
{
  "success": true,
  "role": "STUDENT | INSTRUCTOR | ADMIN",
  "token": "eyJhbGciOiJIUzI1NiJ9...",
  "message": "Login successful",
  "userId": "string"
}
```

**Error Responses:**

*Invalid Credentials (401):*
```json
{
  "success": false,
  "message": "Invalid username or password"
}
```

*Pending Account (403):*
```json
{
  "success": false,
  "message": "PENDING"
}
```

*Inactive Account (403):*
```json
{
  "success": false,
  "message": "INACTIVE"
}
```

---

### 2. Student Registration

**Endpoint:** `POST /api/auth/register/student`

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "categoryIds": ["string", "string", "string"],
  "skillLevel": "BEGINNER | INTERMEDIATE | ADVANCED"
}
```

**Validation Rules:**
- `username`: Required, minimum 3 characters
- `email`: Required, valid email format
- `password`: Required, minimum 6 characters
- `categoryIds`: Required, minimum 3 categories
- `skillLevel`: Required, must be one of: BEGINNER, INTERMEDIATE, ADVANCED

**Success Response (201 Created):**
```
Account created successfully.
```

**Error Response (400 Bad Request):**
```
Error message describing the issue
```

---

### 3. Instructor Application

**Endpoint:** `POST /api/auth/register/instructor`

**Headers:**
```
Content-Type: multipart/form-data
```

**Form Fields:**

*data (JSON string or Blob):*
```json
{
  "username": "string",
  "email": "string",
  "password": "string",
  "yearsOfExperience": "string",
  "specialization": "string",
  "studioName": "string",
  "bio": "string",
  "linkedIn": "string",
  "website": "string"
}
```

*certFile (File):*
- Accepted formats: PDF, JPG, JPEG, PNG
- Field name: `certFile`

**Validation Rules:**
- All fields in `data` are required
- `certFile` is required
- `email` must be valid email format
- `password` minimum 6 characters

**Success Response (201 Created):**
```
Application submitted. Check your e-mail for confirmation.
```

**Error Responses:**

*Conflict (409):*
```
Username or email already exists
```

*Server Error (500):*
```
Internal server error message
```

---

## Category Endpoints

### 4. Get Categories

**Endpoint:** `GET /api/categories`

**Headers:**
```
Content-Type: application/json
```

**Success Response (200 OK):**
```json
[
  {
    "id": "string",
    "name": "string",
    "icon": "string (optional)"
  },
  {
    "id": "string",
    "name": "string",
    "icon": "string (optional)"
  }
]
```

**Error Response (500):**
```json
{
  "error": "Failed to fetch categories"
}
```

---

## Authenticated Endpoints

For all authenticated endpoints, include the JWT token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

### Example Authenticated Request

```http
GET /api/user/profile
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9...
Content-Type: application/json
```

---

## Error Handling

### Standard Error Response Format

```json
{
  "success": false,
  "message": "Error description",
  "timestamp": "2026-05-07T10:30:00Z",
  "path": "/api/endpoint"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| 200  | Success |
| 201  | Created |
| 400  | Bad Request (validation error) |
| 401  | Unauthorized (invalid credentials) |
| 403  | Forbidden (account pending/inactive) |
| 409  | Conflict (duplicate username/email) |
| 500  | Internal Server Error |

---

## Flutter Implementation Examples

### Login Example

```dart
final response = await dio.post(
  '/auth/login',
  data: {
    'username': 'john_doe',
    'password': 'password123',
  },
);

if (response.data['success']) {
  final token = response.data['token'];
  final role = response.data['role'];
  // Save token and navigate
}
```

### Student Registration Example

```dart
final response = await dio.post(
  '/auth/register/student',
  data: {
    'username': 'jane_student',
    'email': 'jane@example.com',
    'password': 'password123',
    'categoryIds': ['cat1', 'cat2', 'cat3'],
    'skillLevel': 'BEGINNER',
  },
);

print(response.data); // "Account created successfully."
```

### Instructor Application Example

```dart
final formData = FormData.fromMap({
  'data': jsonEncode({
    'username': 'instructor_john',
    'email': 'john@example.com',
    'password': 'password123',
    'yearsOfExperience': '5',
    'specialization': 'Ballet',
    'studioName': 'Dance Studio A',
    'bio': 'Experienced ballet teacher...',
    'linkedIn': 'https://linkedin.com/in/john',
    'website': 'https://mystudio.com',
  }),
  'certFile': await MultipartFile.fromFile(
    '/path/to/cert.pdf',
    filename: 'certification.pdf',
  ),
});

final response = await dio.post(
  '/auth/register/instructor',
  data: formData,
  options: Options(
    contentType: 'multipart/form-data',
  ),
);

print(response.data); // "Application submitted..."
```

### Get Categories Example

```dart
final response = await dio.get('/categories');

final categories = (response.data as List)
    .map((json) => Category.fromJson(json))
    .toList();
```

---

## Testing with cURL

### Login
```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"password123"}'
```

### Student Registration
```bash
curl -X POST http://localhost:8080/api/auth/register/student \
  -H "Content-Type: application/json" \
  -d '{
    "username":"newstudent",
    "email":"student@example.com",
    "password":"password123",
    "categoryIds":["cat1","cat2","cat3"],
    "skillLevel":"BEGINNER"
  }'
```

### Get Categories
```bash
curl -X GET http://localhost:8080/api/categories \
  -H "Content-Type: application/json"
```

---

## Notes

1. **Token Expiration**: JWT tokens may expire. Implement token refresh logic if needed.
2. **CORS**: Ensure backend allows requests from your Flutter app's origin.
3. **HTTPS**: In production, always use HTTPS instead of HTTP.
4. **Rate Limiting**: Backend may implement rate limiting on authentication endpoints.
5. **File Size**: Check backend limits for certification file uploads.
