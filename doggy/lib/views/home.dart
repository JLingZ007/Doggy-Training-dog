import 'dart:async';
import 'dart:convert';
import 'dart:math';
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
  List<Map<String, dynamic>> _randomCourses = [];
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadRandomCourses();
    _startAutoScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // โหลดบทเรียนแบบสุ่ม 3 บทจาก Firestore
  void _loadRandomCourses() async {
    final snapshot = await _firestore.collectionGroup('programs').get();

    if (snapshot.docs.isNotEmpty) {
      final allCourses = snapshot.docs.map((doc) {
        return {
          'image': doc['image'],
          'name': doc['name'],
          'documentId': doc.id,
          'categoryId': doc.reference.parent.parent!.id,
        };
      }).toList();

      allCourses.shuffle(Random());

      setState(() {
        _randomCourses = allCourses.take(3).toList();
      });
    }
  }

  // ฟังก์ชันเลื่อน PageView อัตโนมัติ
  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.toInt() + 1;
        if (nextPage >=
            (_randomCourses.isNotEmpty ? _randomCourses.length : 3)) {
          nextPage = 0;
        }
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
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
        backgroundColor: const Color(0xFFD2B48C),
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
            child: FutureBuilder<QuerySnapshot>(
              future: _auth.currentUser != null
                  ? _firestore
                      .collection('users')
                      .doc(_auth.currentUser!.uid)
                      .collection('dogs')
                      .limit(1)
                      .get()
                  : null,
              builder: (context, snapshot) {
                ImageProvider profileImage =
                    const AssetImage('assets/images/dog_profile.jpg');

                if (snapshot.hasData &&
                    snapshot.data!.docs.isNotEmpty &&
                    snapshot.data!.docs.first.data() != null) {
                  final dogData =
                      snapshot.data!.docs.first.data() as Map<String, dynamic>;
                  final imageRaw = dogData['image'] ?? '';

                  if (imageRaw.isNotEmpty) {
                    if (imageRaw.startsWith('http')) {
                      profileImage = NetworkImage(imageRaw);
                    } else {
                      try {
                        profileImage = MemoryImage(base64Decode(imageRaw));
                      } catch (e) {
                        profileImage =
                            const AssetImage('assets/images/dog_profile.jpg');
                      }
                    }
                  }
                }

                return CircleAvatar(
                  backgroundImage: profileImage,
                );
              },
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
                minimumSize:
                    const Size(250, 50), // กำหนดความกว้างและความสูงขั้นต่ำ
                side: const BorderSide(color: Colors.brown, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              //minimumSize: const Size(250, 50),
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
                minimumSize:
                    const Size(250, 50), // กำหนดความกว้างและความสูงขั้นต่ำ
                side: const BorderSide(color: Colors.brown, width: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'คอร์สเรียนทั้งหมด',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            // แสดงบทเรียนแบบสุ่ม 3 บท และเลื่อนอัตโนมัติ
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount:
                          _randomCourses.isNotEmpty ? _randomCourses.length : 3,
                      itemBuilder: (context, index) {
                        if (_randomCourses.isNotEmpty) {
                          final course = _randomCourses[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.trainingDetails,
                                arguments: {
                                  'documentId': course['documentId'],
                                  'categoryId': course['categoryId'],
                                },
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                course['image'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        } else {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              [
                                'assets/images/drip_dog4.jpg',
                                'assets/images/drip_dog2.jpg',
                                'assets/images/drip_dog3.jpg'
                              ][index],
                              fit: BoxFit.cover,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _randomCourses.isNotEmpty ? _randomCourses.length : 3,
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
