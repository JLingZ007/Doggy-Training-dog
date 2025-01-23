import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex; // สถานะของหน้าปัจจุบัน
  final Function(int) onTap; // Callback สำหรับเปลี่ยนหน้า

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      backgroundColor: Colors.brown[200],
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black54,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'หน้าหลัก',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book),
          label: 'บทเรียนของฉัน',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.pets),
          label: 'หมวดหมู่การฝึก',
        ),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, AppRoutes.home);
            break;
          case 1:
            Navigator.pushReplacementNamed(context, AppRoutes.myCourses);
            break;
          case 2:
            Navigator.pushReplacementNamed(context, AppRoutes.courses);
            break;
        }
      },
    );
  }
}
