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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.myCourses);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white, // สีพื้นหลัง
                foregroundColor: Colors.brown, // สีตัวอักษร
                side: const BorderSide(color: Colors.brown, width: 2), // กรอบ
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'คอร์สเรียนของฉัน',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.courses);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.brown,
                side: const BorderSide(color: Colors.brown, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'คอร์สเรียนทั้งหมด',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      children: [
                        Image.asset(
                          'assets/images/drip_dog4.jpg',
                          fit: BoxFit.cover,
                        ),
                        Image.asset(
                          'assets/images/drip_dog2.jpg',
                          fit: BoxFit.cover,
                        ),
                        Image.asset(
                          'assets/images/drip_dog3.jpg',
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 0
                              ? Colors.brown
                              : Colors.brown.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ),
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
