import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/slidebar.dart';
import '../widgets/bottom_navbar.dart';
import '../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _courseImages = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedCourses();
  }

  // ฟังก์ชันโหลดคอร์สที่เรียนจบ
  void _loadCompletedCourses() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _courseImages = []; // ไม่ล็อกอิน ใช้รูปเริ่มต้น
      });
      return;
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_courses')
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        _courseImages = snapshot.docs
            .map((doc) => doc['image'] as String)
            .toList(); // ดึงรูปจาก Firestore
      });
    } else {
      setState(() {
        _courseImages = []; // ถ้าไม่มีคอร์สที่สำเร็จ
      });
    }
  }

  // ฟังก์ชันเปลี่ยนหน้า
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
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: _auth.currentUser != null &&
                      _auth.currentUser!.photoURL != null
                  ? NetworkImage(_auth.currentUser!.photoURL!)
                  : const AssetImage('assets/images/dog_profile.png')
                      as ImageProvider,
            ),
          ),
        ],
      ),
      drawer: SlideBar(),
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
                'คอร์สเรียนของฉัน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // แสดงภาพถ้ามีคอร์สที่เรียนจบ
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      children: _courseImages.isNotEmpty
                          ? _courseImages
                              .map((image) =>
                                  Image.network(image, fit: BoxFit.cover))
                              .toList()
                          : [
                              Image.asset('assets/images/drip_dog4.jpg',
                                  fit: BoxFit.cover),
                              Image.asset('assets/images/drip_dog2.jpg',
                                  fit: BoxFit.cover),
                              Image.asset('assets/images/drip_dog3.jpg',
                                  fit: BoxFit.cover),
                            ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _courseImages.isNotEmpty ? _courseImages.length : 3,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == 0
                              ? Colors.brown
                              : Colors.brown.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
