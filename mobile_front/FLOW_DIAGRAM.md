# Application Flow Diagrams

## 1. Authentication Flow

```
┌─────────────────┐
│   App Starts    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Splash Screen   │
│ (Check Token)   │
└────────┬────────┘
         │
         ├─────────────────┐
         │                 │
    No Token          Has Token
         │                 │
         ▼                 ▼
┌─────────────────┐  ┌──────────────┐
│  Login Screen   │  │ Check Role   │
└────────┬────────┘  └──────┬───────┘
         │                  │
         │            ┌─────┼─────┐
         │            │     │     │
         │        STUDENT INSTRUCTOR ADMIN
         │            │     │     │
         │            ▼     ▼     ▼
         │         ┌───┐ ┌───┐ ┌───┐
         │         │ S │ │ I │ │ A │
         │         │ H │ │ H │ │ H │
         │         │ S │ │ S │ │ S │
         │         └───┘ └───┘ └───┘
         │
    ┌────┴────┐
    │         │
Register   Apply as
Student   Instructor
    │         │
    ▼         ▼
```

## 2. Login Flow

```
┌──────────────────┐
│  Login Screen    │
│                  │
│  [Username]      │
│  [Password]      │
│                  │
│  [Login Button]  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Validate Form   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Call API        │
│  POST /auth/login│
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
 Success   Failure
    │         │
    ▼         ▼
┌───────┐  ┌──────────┐
│ Save  │  │  Show    │
│ Token │  │  Error   │
│ Role  │  │ Message  │
│ UserId│  └──────────┘
└───┬───┘
    │
    ▼
┌───────────────────┐
│ Route by Role     │
│                   │
│ STUDENT    → SHS  │
│ INSTRUCTOR → IHS  │
│ ADMIN      → AHS  │
└───────────────────┘
```

## 3. Student Registration Flow

```
┌──────────────────────┐
│ Registration Screen  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Step 1: Basic Info │
│                      │
│   [Username]         │
│   [Email]            │
│   [Password]         │
│   [Confirm Password] │
│                      │
│   [Next Button]      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Validate Form      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Step 2: Onboarding   │
│                      │
│ Fetch Categories     │
│ from API             │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Display Categories   │
│                      │
│ [☑ Ballet]           │
│ [☑ Yoga]             │
│ [☑ Hip Hop]          │
│ [☐ Salsa]            │
│                      │
│ Skill Level:         │
│ [Beginner ▼]         │
│                      │
│ [Create Account]     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Validate Selection   │
│ (Min 3 categories)   │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
   Valid    Invalid
      │         │
      ▼         ▼
┌─────────┐  ┌──────────┐
│ Call API│  │  Show    │
│ POST    │  │  Error   │
│ /register│ └──────────┘
│ /student│
└────┬────┘
     │
     ▼
┌──────────────────────┐
│ Show Success Message │
│ Navigate to Login    │
└──────────────────────┘
```

## 4. Instructor Application Flow

```
┌──────────────────────┐
│ Application Screen   │
│                      │
│ Account Info:        │
│ [Username]           │
│ [Email]              │
│ [Password]           │
│ [Confirm Password]   │
│                      │
│ Professional Info:   │
│ [Years Experience]   │
│ [Specialization]     │
│ [Studio Name]        │
│ [Bio]                │
│ [LinkedIn]           │
│ [Website]            │
│                      │
│ Certification:       │
│ [Upload File]        │
│                      │
│ [Submit Application] │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Validate Form      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Pick File          │
│   (PDF/Image)        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Create Multipart     │
│ Form Data            │
│                      │
│ data: JSON           │
│ certFile: File       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Call API             │
│ POST /register/      │
│ instructor           │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
   Success   Failure
      │         │
      ▼         ▼
┌──────────┐ ┌──────────┐
│  Show    │ │  Show    │
│ Success  │ │  Error   │
│ Dialog   │ │ Message  │
└────┬─────┘ └──────────┘
     │
     ▼
┌──────────────────────┐
│ Navigate to Login    │
└──────────────────────┘
```

## 5. State Management Flow

```
┌──────────────────────┐
│   AuthProvider       │
│                      │
│ - token              │
│ - role               │
│ - userId             │
│ - isLoading          │
│ - errorMessage       │
└──────────┬───────────┘
           │
           ├─────────────────┐
           │                 │
           ▼                 ▼
┌──────────────────┐  ┌──────────────────┐
│  Secure Storage  │  │   UI Screens     │
│                  │  │                  │
│  - jwt_token     │  │  - Login         │
│  - user_role     │  │  - Registration  │
│  - user_id       │  │  - Home Screens  │
└──────────────────┘  └──────────────────┘
```

## 6. API Client Flow

```
┌──────────────────────┐
│   API Request        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Interceptor        │
│                      │
│ 1. Read Token from   │
│    Secure Storage    │
│                      │
│ 2. Add Authorization │
│    Header            │
│    Bearer <token>    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Send Request       │
│   to Backend         │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
   Success   Error
      │         │
      ▼         ▼
┌──────────┐ ┌──────────┐
│  Parse   │ │  Handle  │
│ Response │ │  Error   │
└──────────┘ └──────────┘
```

## 7. Navigation Flow (go_router)

```
┌──────────────────────┐
│   Route Request      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Redirect Logic     │
│                      │
│ Check:               │
│ - isAuthenticated    │
│ - role               │
│ - isLoading          │
└──────────┬───────────┘
           │
    ┌──────┴──────┐
    │             │
Not Auth      Authenticated
    │             │
    ▼             ▼
┌────────┐   ┌──────────────┐
│ Login  │   │ Check Role   │
│ Screen │   └──────┬───────┘
└────────┘          │
              ┌─────┼─────┐
              │     │     │
          STUDENT INSTRUCTOR ADMIN
              │     │     │
              ▼     ▼     ▼
           ┌───┐ ┌───┐ ┌───┐
           │SHS│ │IHS│ │AHS│
           └───┘ └───┘ └───┘
```

## 8. Error Handling Flow

```
┌──────────────────────┐
│   API Call           │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Try-Catch Block    │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
   Success   Exception
      │         │
      ▼         ▼
┌──────────┐ ┌──────────────────┐
│  Return  │ │  Check Exception │
│  Data    │ │  Type            │
└──────────┘ └────────┬─────────┘
                      │
              ┌───────┼───────┐
              │       │       │
          DioError  Network  Other
              │       │       │
              ▼       ▼       ▼
         ┌────────────────────┐
         │  Parse Error       │
         │  Message           │
         └────────┬───────────┘
                  │
                  ▼
         ┌────────────────────┐
         │  Show SnackBar     │
         │  with Error        │
         └────────────────────┘
```

## 9. Logout Flow

```
┌──────────────────────┐
│   User Clicks        │
│   Logout Button      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   AuthProvider       │
│   .logout()          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Clear State        │
│                      │
│   token = null       │
│   role = null        │
│   userId = null      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Delete from        │
│   Secure Storage     │
│                      │
│   - jwt_token        │
│   - user_role        │
│   - user_id          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Notify Listeners   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   go_router          │
│   Redirects to       │
│   Login Screen       │
└──────────────────────┘
```

## 10. Category Loading Flow

```
┌──────────────────────┐
│ Student Registration │
│ Screen Loads         │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ CategoryProvider     │
│ .fetchCategories()   │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Set isLoading = true │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Call API             │
│ GET /categories      │
└──────────┬───────────┘
           │
      ┌────┴────┐
      │         │
   Success   Failure
      │         │
      ▼         ▼
┌──────────┐ ┌──────────┐
│  Parse   │ │  Set     │
│  Data    │ │  Error   │
│  to List │ │  Message │
└────┬─────┘ └────┬─────┘
     │            │
     └─────┬──────┘
           │
           ▼
┌──────────────────────┐
│ Set isLoading = false│
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Notify Listeners     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ UI Updates           │
│ (Shows categories    │
│  or error message)   │
└──────────────────────┘
```

## Legend

```
┌─────┐
│ Box │  = Process/Screen
└─────┘

   │
   ▼     = Flow Direction

┌──┴──┐
│     │  = Decision Point
```

## Screen Abbreviations

- **SHS** = Student Home Screen
- **IHS** = Instructor Home Screen
- **AHS** = Admin Home Screen
