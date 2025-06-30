// routes/app_navigator.dart
import 'package:dog_training_app/views/program.dart';
import 'package:flutter/material.dart';
import '../views/home.dart' as views_home;
import '../main.dart'; // ตรวจสอบว่า MainPage อยู่ในไฟล์นี้
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

class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    print('Navigating to: ${settings.name}'); // เพิ่ม debug log
    
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => views_home.HomePage(),
          settings: settings, // เพิ่มบรรทัดนี้
        );
        
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginPage(),
          settings: settings,
        );
        
      case AppRoutes.dogProfiles:
        return MaterialPageRoute(
          builder: (_) => DogProfilesPage(),
          settings: settings,
        );
        
      case AppRoutes.AddDogPage:
        return MaterialPageRoute(
          builder: (_) => AddDogPage(),
          settings: settings,
        );
        
      case AppRoutes.editDogProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditDogProfilePage(
            dogData: args?['dogData'],
            docId: args?['docId'],
          ),
          settings: settings,
        );
        
      case AppRoutes.myCourses:
        return MaterialPageRoute(
          builder: (_) => MyCoursesPage(),
          settings: settings,
        );
        
      case AppRoutes.mainPage:
        return MaterialPageRoute(
          builder: (_) => MainPage(), // MainPage ต้องมาจาก main.dart
          settings: settings,
        );
        
      case AppRoutes.courses:
        return MaterialPageRoute(
          builder: (_) => CoursesPage(),
          settings: settings,
        );
        
      case AppRoutes.trainingPrograms:
        final categoryId = settings.arguments as String;
        print('Navigating to TrainingProgramsPage with ID: $categoryId');
        return MaterialPageRoute(
          builder: (_) => TrainingProgramsPage(categoryId: categoryId),
          settings: settings,
        );
        
      case AppRoutes.trainingDetails:
        final args = settings.arguments as Map<String, dynamic>;
        print('Navigating to TrainingDetailsPage with ID: ${args['documentId']}');
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsPage(
            documentId: args['documentId'],
            categoryId: args['categoryId'],
          ),
          settings: settings,
        );
        
      case AppRoutes.clicker:
        return MaterialPageRoute(
          builder: (_) => ClickerPage(),
          settings: settings,
        );
        
      case AppRoutes.whistle:
        return MaterialPageRoute(
          builder: (_) => WhistlePage(),
          settings: settings,
        );
      
      // Chat routes
      case AppRoutes.chat:
        return MaterialPageRoute(
          builder: (_) => ChatPage(),
          settings: settings,
        );
        
      case AppRoutes.chatHistory:
        return MaterialPageRoute(
          builder: (_) => ChatHistoryPage(),
          settings: settings,
        );
        
      // Community routes
      case AppRoutes.community:
        return MaterialPageRoute(
          builder: (_) => CommunityPage(),
          settings: settings,
        );
        
      case AppRoutes.groupDetail:
        final group = settings.arguments as CommunityGroup;
        return MaterialPageRoute(
          builder: (_) => GroupDetailPage(group: group),
          settings: settings,
        );
        
      default:
        print('Page not found: ${settings.name}');
        return MaterialPageRoute(
          builder: (context) => Scaffold( // เปลี่ยนจาก (_) เป็น (context)
            appBar: AppBar(
              title: Text('หน้าไม่พบ'),
              backgroundColor: const Color(0xFFD2B48C),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'ไม่พบหน้าที่ต้องการ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Route: ${settings.name}',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushReplacementNamed(
                      context, // เปลี่ยนจาก _.context เป็น context
                      AppRoutes.home,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD2B48C),
                    ),
                    child: Text('กลับหน้าหลัก'),
                  ),
                ],
              ),
            ),
          ),
          settings: settings,
        );
    }
  }
}