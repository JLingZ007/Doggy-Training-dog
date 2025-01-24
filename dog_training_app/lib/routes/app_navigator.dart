import 'package:dog_training_app/views/program.dart';
import 'package:flutter/material.dart';
import '../views/home.dart';
import '../main.dart'; // นำเข้า MainPage
// import '../views/login.dart';
// import '../views/profile.dart';
import '../views/courses.dart';
import '../views/training_details.dart';
// import '../views/my_courses.dart';
import 'app_routes.dart';

class AppNavigator {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => HomePage());
      case AppRoutes.mainPage:
        return MaterialPageRoute(builder: (_) => MainPage()); // หน้า MainPage
      case AppRoutes.courses:
        return MaterialPageRoute(builder: (_) => CoursesPage());
      case AppRoutes.trainingPrograms:
        // เพิ่ม Debug
        final categoryId = settings.arguments as String;
        print('Navigating to TrainingProgramsPage with ID: $categoryId');
        return MaterialPageRoute(
          builder: (_) => TrainingProgramsPage(categoryId: categoryId),
        );
      case AppRoutes.trainingDetails:
        // เพิ่ม Debug
        final args = settings.arguments as String;
        print('Navigating to TrainingDetailsPage with ID: $args');
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsPage(documentId: args),
        );
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
