import 'package:dog_training_app/views/program.dart';
import 'package:flutter/material.dart';
import '../views/home.dart' as views_home;
import '../main.dart';
import '../views/dog_profiles.dart';
import '../views/edit_dog_profile.dart';
import '../views/add_dog.dart';
import '../views/courses.dart';
import '../views/training_details.dart';
import '../views/myCourses.dart';
import '../views/clicker_page.dart';
import '../views/whistle_page.dart';
import '../views/chat_page.dart';
import '../views/chat_history_page.dart';
import '../views/community_page.dart';
import '../views/group_detail_page.dart';
import '../models/community_models.dart';
import 'app_routes.dart';
import '../views/login_page.dart';
import '../views/register_page.dart';

class AppNavigator {
  // ── Bottom nav pages: ไม่มี transition เลย (instant swap) ─────────────────
  static Route<T> _instantRoute<T>(
      Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  // ── Push pages (detail, modal): fade-in เบาๆ ─────────────────────────────
  static Route<T> _fadeRoute<T>(Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
    );
  }

  // ── Push pages (login, register, dog): slide up เบาๆ ──────────────────────
  static Route<T> _slideUpRoute<T>(
      Widget page, RouteSettings settings) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        ));
        return FadeTransition(
          opacity: CurvedAnimation(
              parent: animation, curve: Curves.easeOut),
          child: SlideTransition(position: tween, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
    );
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      // ── Bottom nav (instant — ไม่มี animation ทำให้รู้สึก native) ──────────
      case AppRoutes.home:
        return _instantRoute(views_home.HomePage(), settings);

      case AppRoutes.courses:
        return _instantRoute(CoursesPage(), settings);

      case AppRoutes.community:
        return _instantRoute(CommunityPage(), settings);

      case AppRoutes.chat:
        return _instantRoute(ChatPage(), settings);

      // ── Auth pages (slide up) ────────────────────────────────────────────
      case AppRoutes.mainPage:
        return _slideUpRoute(MainPage(), settings);

      case AppRoutes.login:
        return _slideUpRoute(LoginPage(), settings);

      case AppRoutes.register:
        return _slideUpRoute(RegisterPage(), settings);

      // ── Detail / sub pages (fade) ─────────────────────────────────────────
      case AppRoutes.dogProfiles:
        return _fadeRoute(DogProfilesPage(), settings);

      case AppRoutes.AddDogPage:
        return _fadeRoute(AddDogPage(), settings);

      case AppRoutes.editDogProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return _fadeRoute(
          EditDogProfilePage(
            dogData: args?['dogData'],
            docId: args?['docId'],
          ),
          settings,
        );

      case AppRoutes.myCourses:
        return _fadeRoute(MyCoursesPage(), settings);

      case AppRoutes.trainingPrograms:
        final categoryId = settings.arguments as String;
        return _fadeRoute(
            TrainingProgramsPage(categoryId: categoryId), settings);

      case AppRoutes.trainingDetails:
        final args = settings.arguments as Map<String, dynamic>;
        return _fadeRoute(
          TrainingDetailsPage(
            documentId: args['documentId'],
            categoryId: args['categoryId'],
            dogId: args['dogId'] as String?,
          ),
          settings,
        );

      case AppRoutes.clicker:
        return _fadeRoute(ClickerPage(), settings);

      case AppRoutes.whistle:
        return _fadeRoute(WhistlePage(), settings);

      case AppRoutes.chatHistory:
        return _fadeRoute(ChatHistoryPage(), settings);

      case AppRoutes.groupDetail:
        final group = settings.arguments as CommunityGroup;
        return _fadeRoute(GroupDetailPage(group: group), settings);

      // ── 404 ───────────────────────────────────────────────────────────────
      default:
        return _fadeRoute(
          Scaffold(
            backgroundColor: const Color(0xFFF7EFE7),
            appBar: AppBar(
              title: const Text('ไม่พบหน้าที่ต้องการ'),
              backgroundColor: const Color(0xFFEFE2D3),
              foregroundColor: const Color(0xFF6D4C41),
              elevation: 0,
            ),
            body: Builder(
              builder: (context) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off_rounded,
                        size: 56, color: Color(0xFFB08968)),
                    const SizedBox(height: 14),
                    const Text('ไม่พบหน้าที่ต้องการ',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6D4C41))),
                    const SizedBox(height: 6),
                    Text(settings.name ?? '',
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFFB08968))),
                    const SizedBox(height: 22),
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                          context, AppRoutes.home),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6D4C41),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('กลับหน้าหลัก',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          settings,
        );
    }
  }
}