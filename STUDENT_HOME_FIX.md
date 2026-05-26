# Student Home Screen Fix

## Problem
The student mobile home screen was showing an error and not loading properly.

## Root Causes Identified

1. **API Call Failure**: The app was trying to load recommended and popular courses, but if either API failed, the entire screen would fail.
2. **Course Model Parsing**: The Course model's `fromJson` method wasn't handling snake_case field names from the recommendations API.
3. **Java Compatibility**: Used `.toList()` which could have compatibility issues in some environments.

## Changes Made

### Backend Changes

1. **CourseController.java**
   - Added endpoint: `GET /api/courses/most-popular?limit=10`
   - Returns courses sorted by enrollment count (descending)

2. **CourseService.java**
   - Added `getMostPopularCourses(int limit)` method
   - Sorts published courses by enrollment count
   - Changed `.toList()` to `.collect(Collectors.toList())` for better compatibility

### Mobile Frontend Changes

1. **course_service.dart**
   - Added `getMostPopularCourses({int limit = 10})` method

2. **course.dart (Model)**
   - Enhanced `fromJson` to handle both camelCase and snake_case field names
   - Added support for `lesson_count`, `course_id`, `is_free`, `thumbnail_url`, `category` fields
   - Fixed lessonCount to use JSON value if available, otherwise calculate from lessons array

3. **student_home_screen.dart**
   - Added state variables for recommended and popular courses
   - **Improved error handling**: Core data loads first, then recommended/popular courses load separately
   - If recommendations or popular courses fail, they simply won't show (non-blocking)
   - Added `_buildDiscoveryCourseCard()` widget with:
     - Check icon (✓) on top-left if student is enrolled
     - Same styling as library cards but without progress bar
     - Displays: thumbnail, title, level, price, lesson count, instructor
   - Home tab now shows:
     - Greeting card
     - Stats row
     - Badges (if any)
     - **Recommended for You** section (horizontal scroll)
     - **Most Popular** section with "Show All" button (horizontal scroll, 10 courses max)

## How to Test

### 1. Restart Backend
```bash
cd d:\PFE_Application\WEB\Pfe_Backend
mvn clean install
mvn spring-boot:run
```

### 2. Restart Mobile App
```bash
cd d:\PFE_Application\WEB\mobile_front
flutter clean
flutter pub get
flutter run
```

### 3. Test Scenarios

#### Scenario 1: Normal Load
- Login as a student
- Home screen should show:
  - Greeting card with username
  - Stats (courses, streak, categories, badges)
  - Recommended courses (if available)
  - Most Popular courses (sorted by enrollment count)
  - Check icon on courses you're enrolled in

#### Scenario 2: No Recommendations
- If recommendations API fails or returns empty:
  - Home screen still loads
  - Only "Most Popular" section shows

#### Scenario 3: No Popular Courses
- If no courses exist or API fails:
  - Home screen still loads
  - Only "Recommended" section shows (if available)

#### Scenario 4: Complete Failure
- If core APIs fail:
  - Error screen with "Retry" button shows
  - Error message displays the actual error

## Expected Behavior

### Home Tab Layout
```
┌─────────────────────────────────┐
│  Welcome back, [Username]       │
│  X courses enrolled             │
└─────────────────────────────────┘

┌──────┬──────┬──────┬──────┐
│Courses│Streak│Categ.│Badges│
└──────┴──────┴──────┴──────┘

My Badges
○ ○ ○ (horizontal scroll)

Recommended for You
┌────┐ ┌────┐ ┌────┐
│ ✓  │ │    │ │ ✓  │ (horizontal scroll)
│Crs1│ │Crs2│ │Crs3│
└────┘ └────┘ └────┘

Most Popular          [Show All]
┌────┐ ┌────┐ ┌────┐
│    │ │ ✓  │ │    │ (horizontal scroll)
│Crs1│ │Crs2│ │Crs3│
└────┘ └────┘ └────┘
```

### Course Card Features
- ✓ Check icon if enrolled (top-left, gold circle)
- Thumbnail image or placeholder
- Course title (2 lines max)
- Level chip (e.g., "Beginner")
- Price chip (e.g., "Free" or "$50")
- Lesson count with icon
- Instructor name with icon

## Troubleshooting

### Error: "Failed to load recommendations"
- Check if `/api/recommendations/student/{studentId}` endpoint exists
- This is non-blocking, home screen will still load

### Error: "Failed to load popular courses"
- Check if `/api/courses/most-popular` endpoint exists
- Verify backend is running
- This is non-blocking, home screen will still load

### Error: "Failed to load stats"
- This is a core API, will show error screen
- Check if `/api/students/stats/{userId}` endpoint is working
- Click "Retry" button to reload

### Courses not showing check icon
- Verify student is actually enrolled in the course
- Check `_enrolledCourseIds` set is populated correctly
- Ensure `courseId` matches between enrolled courses and displayed courses

## API Endpoints Used

1. `GET /api/users/me` - Get current user profile
2. `GET /api/students/stats/{userId}` - Get student statistics
3. `GET /api/students/{id}/courses` - Get all enrolled courses
4. `GET /api/students/{id}/courses/free` - Get free enrolled courses
5. `GET /api/students/{id}/courses/paid` - Get paid enrolled courses
6. `GET /api/badges/my-status` - Get badge status
7. `GET /api/notifications` - Get notifications
8. `GET /api/notifications/unread/count` - Get unread count
9. `GET /api/recommendations/student/{studentId}?topN=10` - Get recommendations (optional)
10. `GET /api/courses/most-popular?limit=10` - Get popular courses (optional)

## Notes

- Recommendations and popular courses are loaded separately and won't block the main UI
- If either fails, the section simply won't appear
- The check icon only appears on courses the student is enrolled in
- "Show All" button currently shows a placeholder dialog
- Course cards match the library tab design but without progress bars
