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
      // case AppRoutes.login:
      //   return MaterialPageRoute(builder: (_) => LoginPage());
      // case AppRoutes.profile:
      //   return MaterialPageRoute(builder: (_) => ProfilePage());
      case AppRoutes.courses:
        return MaterialPageRoute(builder: (_) => CoursesPage());
      // case AppRoutes.myCourses:
      //   return MaterialPageRoute(builder: (_) => MyCoursesPage());
      case AppRoutes.trainingDetails:
        final args = settings.arguments as String; // รับ documentId
        return MaterialPageRoute(
          builder: (_) => TrainingDetailsPage(documentId: args),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Page not found: ${settings.name}')),
          ),
        );
    }
  }
}
