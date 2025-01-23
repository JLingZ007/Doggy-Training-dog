import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class SlideBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Colors.brown[200],
            ),
            currentAccountPicture: CircleAvatar(
              backgroundImage: AssetImage('assets/images/dog_profile.png'),
            ),
            accountName: const Text('ชื่อสุนัข: Buddy'),
            accountEmail: const Text('พันธุ์: Pomeranian'),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('หน้าหลัก'),
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('โปรไฟล์'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.profile);
            },
          ),
          ListTile(
            leading: const Icon(Icons.book),
            title: const Text('คอร์สเรียนของฉัน'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.myCourses);
            },
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: const Text('คอร์สทั้งหมด'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.courses);
            },
          ),
        ],
      ),
    );
  }
}
