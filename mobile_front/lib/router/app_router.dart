import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_role.dart';
import '../screens/login_screen.dart';
import '../screens/student/student_registration_screen.dart';
import '../screens/instructor/instructor_application_screen.dart';
import '../screens/student/student_main_layout.dart';
import '../screens/instructor/instructor_home_screen.dart';
import '../screens/instructor/instructor_main_layout.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/verify_reset_code_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/notification_screen.dart';
import '../screens/instructor/instructor_drafts_screen.dart';
import '../screens/instructor/instructor_archived_screen.dart';
import '../screens/instructor/instructor_course_detail_screen.dart';
import '../screens/instructor/instructor_student_profile_screen.dart';

class AppRouter {
  final AuthProvider authProvider;

  AppRouter(this.authProvider);

  late final GoRouter router = GoRouter(
    refreshListenable: authProvider,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authProvider.isAuthenticated;
      final role = authProvider.role;
      final isLoading = authProvider.isLoading;
      final loc = state.matchedLocation;

      // Never interrupt while loading — let the current screen handle it
      if (isLoading) return null;

      // Public routes — always accessible when not authenticated
      const publicRoutes = {
        '/login',
        '/register/student',
        '/register/instructor',
        '/forgot-password',
        '/forgot-password/verify',
        '/forgot-password/reset',
      };

      if (!isAuthenticated) {
        // Already on a public route — stay there
        if (publicRoutes.contains(loc)) return null;
        // Splash with no token — go to login
        return '/login';
      }

      // Authenticated — redirect away from public/splash to the role dashboard
      if (isAuthenticated && role != null) {
        if (loc == '/login' || loc == '/splash') {
          switch (role) {
            case UserRole.student:
              return '/student/home';
            case UserRole.instructor:
              return '/instructor/home';
            case UserRole.admin:
              return '/admin/home';
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register/student',
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: '/register/instructor',
        builder: (context, state) => const InstructorApplicationScreen(),
      ),
      GoRoute(
        path: '/student/home',
        builder: (context, state) => const StudentMainLayout(),
      ),

      GoRoute(
        path: '/instructor/home',
        builder: (context, state) => const InstructorMainLayout(),
      ),
      GoRoute(
        path: '/instructor/drafts',
        builder: (context, state) => const InstructorDraftsScreen(),
      ),
      GoRoute(
        path: '/instructor/archived',
        builder: (context, state) => const InstructorArchivedScreen(),
      ),
      GoRoute(
        path: '/instructor/course/:courseId',
        builder: (context, state) {
          final courseId = state.pathParameters['courseId']!;
          return InstructorCourseDetailScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/instructor/student/:userId/:name',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final name = state.pathParameters['name']!;
          return InstructorStudentProfileScreen(
            studentUserId: userId,
            studentName: name,
          );
        },
      ),
      GoRoute(
        path: '/admin/home',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/forgot-password/verify',
        builder: (context, state) => VerifyResetCodeScreen(
          identifier: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/forgot-password/reset',
        builder: (context, state) => ResetPasswordScreen(
          userId: state.extra as String,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
    ],
  );
}
