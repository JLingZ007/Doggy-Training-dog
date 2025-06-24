import 'package:dog_training_app/views/program.dart';
import 'package:flutter/material.dart';
import '../views/home.dart';
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
import '../views/chat_history_page.dart'; // เพิ่ม import
import 'app_routes.dart';
import '../views/login_page.dart';

class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());
      case AppRoutes.dogProfiles:
        return MaterialPageRoute(builder: (_) => DogProfilesPage());
      case AppRoutes.AddDogPage:
        return MaterialPageRoute(builder: (_) => AddDogPage());
      case AppRoutes.editDogProfile:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => EditDogProfilePage(
            dogData: args?['dogData'],
            docId: args?['docId'],
          ),
        );
      case AppRoutes.myCourses:
        return MaterialPageRoute(builder: (_) => MyCoursesPage());
      case AppRoutes.mainPage:
        return MaterialPageRoute(builder: (_) => MainPage());
      case AppRoutes.courses:
        return MaterialPageRoute(builder: (_) => CoursesPage());
      case AppRoutes.trainingPrograms:
        final categoryId = settings.arguments as String;
        print('Navigating to TrainingProgramsPage with ID: $categoryId');
        return MaterialPageRoute(
          builder: (_) => TrainingProgramsPage(categoryId: categoryId),
        );
      case AppRoutes.trainingDetails:
        final args = settings.arguments as Map<String, dynamic>;
        print('Navigating to TrainingDetailsPage with ID: ${args['documentId']}');
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsPage(
            documentId: args['documentId'],
            categoryId: args['categoryId'],
          ),
        );
      case AppRoutes.clicker:
        return MaterialPageRoute(builder: (_) => ClickerPage());
      case AppRoutes.whistle:
        return MaterialPageRoute(builder: (_) => WhistlePage());
      
      // Chat routes
      case AppRoutes.chat:
        return MaterialPageRoute(builder: (_) => ChatPage());
      case AppRoutes.chatHistory:
        return MaterialPageRoute(builder: (_) => ChatHistoryPage());
        
      default:
        print('Page not found: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
        );
    }
  }
}