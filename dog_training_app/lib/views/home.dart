import 'package:flutter/material.dart';
import '../widgets/slidebar.dart';
import '../widgets/bottom_navbar.dart';
import '../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; // ตัวแปรสำหรับเก็บสถานะหน้าปัจจุบัน

  // ฟังก์ชันเปลี่ยนหน้าจอ
  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        elevation: 0,
        title: const Text(
          'หน้าหลัก',
          style: TextStyle(color: Colors.black),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // เปิด SlideBar
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/dog_profile.png'),
            ),
          ),
        ],
      ),
      drawer: SlideBar(), // ใช้ SlideBar
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.myCourses);
              },
              child: const Text('คอร์สเรียนของฉัน'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.courses);
              },
              child: const Text('คอร์สเรียนทั้งหมด'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex, // สถานะของหน้าปัจจุบัน
        onTap: _onNavBarTap, // Callback สำหรับเปลี่ยนหน้า
      ),
    );
  }
}
