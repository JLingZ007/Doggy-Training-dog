import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

class SlideBar extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Drawer(
      child: ListView(
        children: [
          // ตรวจสอบว่าผู้ใช้ล็อกอินหรือไม่
          user == null
              ? UserAccountsDrawerHeader(
                  decoration: BoxDecoration(color: Colors.brown[200]),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/dog_profile.png'),
                  ),
                  accountName: Text('ไม่ได้เข้าสู่ระบบ'),
                  accountEmail: Text('กรุณาล็อกอินเพื่อดูโปรไฟล์สุนัข'),
                )
              : FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('dogs')
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      // ถ้าไม่มีข้อมูลสุนัขให้แสดงค่าเริ่มต้น
                      return UserAccountsDrawerHeader(
                        decoration: BoxDecoration(color: Colors.brown[200]),
                        currentAccountPicture: CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/dog_profile.png'),
                        ),
                        accountName: const Text('ไม่มีโปรไฟล์สุนัข'),
                        accountEmail: const Text('กรุณาเพิ่มสุนัขของคุณ'),
                      );
                    }

                    // ดึงข้อมูลสุนัขตัวแรกจาก Firestore
                    final dogData = snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    final profilePic = (dogData['image'] != null &&
                            dogData['image'].isNotEmpty)
                        ? NetworkImage(dogData['image'])
                        : const AssetImage('assets/images/dog_profile.png')
                            as ImageProvider;
                    final name = dogData['name'] ?? 'ไม่ระบุ';

                    return UserAccountsDrawerHeader(
                      decoration: BoxDecoration(color: Colors.brown[200]),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: profilePic,
                      ),
                      accountName: Text(name),
                      accountEmail: Text('🐶 โปรไฟล์สุนัขของคุณ'),
                    );
                  },
                ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('หน้าหลัก'),
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          ListTile(
            leading: const Icon(Icons.pets),
            title: const Text('ข้อมูลสุนัขของคุณ'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.dogProfiles);
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
