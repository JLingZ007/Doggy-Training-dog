import 'dart:convert';

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
                  decoration: BoxDecoration(color: Color(0xFFD2B48C)),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/images/dog_profile.jpg'),
                  ),
                  accountName: Text('ไม่ได้เข้าสู่ระบบ'),
                  accountEmail: Text('กรุณาล็อกอินเพื่อดูโปรไฟล์สุนัข'),
                )
              : FutureBuilder<QuerySnapshot>(
                  future: _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('dogs')
                      .limit(1) // ดึงแค่ตัวแรก
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return UserAccountsDrawerHeader(
                        decoration:
                            const BoxDecoration(color: Color(0xFFD2B48C)),
                        currentAccountPicture: const CircleAvatar(
                          backgroundImage:
                              AssetImage('assets/images/dog_profile.jpg'),
                        ),
                        accountName: Text(user.displayName ?? user.email ?? 'ผู้ใช้'),
                        accountEmail: const Text('กรุณาเพิ่มสุนัขของคุณ'),
                      );
                    }

                    final dogData = snapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    final String imageRaw = dogData['image'] ?? '';
                    ImageProvider profileImage;

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
                    } else {
                      profileImage =
                          const AssetImage('assets/images/dog_profile.jpg');
                    }

                    return UserAccountsDrawerHeader(
                      decoration: const BoxDecoration(color: Color(0xFFD2B48C)),
                      currentAccountPicture: CircleAvatar(
                        backgroundImage: profileImage,
                      ),
                      accountName: Text(dogData['name'] ?? 'ไม่ระบุ'),
                      accountEmail: const Text('🐶 โปรไฟล์สุนัขของคุณ'),
                    );
                  },
                ),

          // หมวดหมู่หลัก
          ListTile(
            leading: const Icon(Icons.home, color: Colors.brown),
            title: const Text('หน้าหลัก'),
            onTap: () {
              Navigator.pushReplacementNamed(context, AppRoutes.home);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.pets, color: Colors.orange),
            title: const Text('ข้อมูลสุนัขของคุณ'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.dogProfiles);
            },
          ),

          const Divider(thickness: 1),
          
          // หมวดหมู่การเรียนรู้
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'การเรียนรู้',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.book, color: Colors.green),
            title: const Text('คอร์สเรียนของฉัน'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.myCourses);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.menu_book, color: Colors.blue),
            title: const Text('คอร์สทั้งหมด'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.courses);
            },
          ),

          const Divider(thickness: 1),
          
          // หมวดหมู่แชทและเครื่องมือ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'ผู้ช่วยและเครื่องมือ',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),

          // แชทบอท
          ListTile(
            leading: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.chat_bubble, color: Colors.blue[600]),
            ),
            title: const Text('แชทบอทสุนัข'),
            subtitle: const Text('ถามคำถามเกี่ยวกับสุนัข'),
            trailing: user != null 
                ? Icon(Icons.chevron_right, color: Colors.grey)
                : Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
            onTap: () {
              if (user != null) {
                Navigator.pushNamed(context, AppRoutes.chat);
              } else {
                _showLoginRequiredDialog(context, 'แชทบอท');
              }
            },
          ),

          // ประวัติการสนทนา
          if (user != null)
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history, color: Colors.green[600]),
              ),
              title: const Text('ประวัติการสนทนา'),
              subtitle: const Text('ดูการสนทนาที่ผ่านมา'),
              trailing: Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.chatHistory);
              },
            ),

          const Divider(thickness: 1),

          // เครื่องมือฝึกสุนัข
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'เครื่องมือฝึกสุนัข',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          ListTile(
            leading: const Icon(Icons.touch_app, color: Colors.purple),
            title: const Text('คลิกเกอร์'),
            subtitle: const Text('เครื่องมือฝึกด้วยเสียง'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.clicker);
            },
          ),
          
          ListTile(
            leading: const Icon(Icons.volume_up, color: Colors.red),
            title: const Text('นกหวีด'),
            subtitle: const Text('เครื่องมือเรียกสุนัข'),
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.whistle);
            },
          ),

          const Divider(thickness: 1),
          
          // การจัดการบัญชี
          if (user == null)
            ListTile(
              leading: const Icon(Icons.login, color: Colors.green),
              title: const Text('เข้าสู่ระบบ'),
              subtitle: const Text('ใช้งานฟีเจอร์เพิ่มเติม'),
              onTap: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
            ),

          if (user != null)
            ListTile(
              leading: const Icon(Icons.power_settings_new, color: Colors.red),
              title: const Text('ออกจากระบบ'),
              subtitle: Text(user.email ?? ''),
              onTap: () {
                _showLogoutDialog(context);
              },
            ),

          // ข้อมูลเวอร์ชัน
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Doggy Training v1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Dialog แจ้งเตือนให้ login สำหรับฟีเจอร์ที่ต้องการ authentication
  void _showLoginRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[600]),
              SizedBox(width: 8),
              Text('ต้องเข้าสู่ระบบ'),
            ],
          ),
          content: Text('กรุณาเข้าสู่ระบบก่อนใช้งาน$feature'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('เข้าสู่ระบบ'),
            ),
          ],
        );
      },
    );
  }

  // แสดง Popup ยืนยันการออกจากระบบ
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFD2B48C),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ใช้ icon แทนรูปภาพถ้าไม่มีไฟล์
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  size: 40,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'คุณต้องการออกจากระบบหรือไม่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ข้อมูลในเครื่องจะถูกลบออก',
                style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(80, 40),
                    ),
                    onPressed: () async {
                      await _auth.signOut();
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                    child: const Text('ออกจากระบบ'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[400],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      minimumSize: Size(80, 40),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('ยกเลิก'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}