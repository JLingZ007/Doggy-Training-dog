import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  void _navigateTo(BuildContext context, String routeName, int index) {
    if (ModalRoute.of(context)?.settings.name != routeName) {
      Navigator.pushNamed(context, routeName);
    }
    onTap(index);
  }

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
            _navigateTo(context, AppRoutes.home, index);
            break;
          case 1:
            _navigateTo(context, AppRoutes.myCourses, index);
            break;
          case 2:
            _navigateTo(context, AppRoutes.courses, index);
            break;
        }
      },
    );
  }
}
