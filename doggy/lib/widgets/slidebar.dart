// widgets/slide_bar.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';
import '../services/user_service.dart';

class SlideBar extends StatefulWidget {
  @override
  _SlideBarState createState() => _SlideBarState();
}

class _SlideBarState extends State<SlideBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Color scheme ที่เข้ากับ BottomNavBar
  static const Color primaryColor = Color(0xFFD2B48C); // สีหลัก
  static const Color accentColor = Color(0xFF8B4513); // สีน้ำตาลเข้ม
  static const Color secondaryColor = Color(0xFFC19A5B); // สีเข้มกว่า
  static const Color surfaceColor = Colors.white; // สีพื้นผิว
  static const Color textPrimary = Color(0xFF5D4037); // สีข้อความหลัก
  static const Color textSecondary = Color(0xFF8D6E63); // สีข้อความรอง

  @override
  void initState() {
    super.initState();
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      if (mounted) {
        setState(() {
          // This will trigger a rebuild when auth state changes
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Container(
      decoration: BoxDecoration(
        color: primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Drawer(
        backgroundColor: Colors.transparent,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ส่วน Header
            user == null
                ? _buildGuestHeader()
                : _buildUserHeader(user),

            // เนื้อหาหลัก
            Container(
              color: surfaceColor,
              child: Column(
                children: [
                  // หมวดหมู่หลัก
                  _buildSimpleMenuItem(
                    icon: Icons.home,
                    activeIcon: Icons.home,
                    title: 'หน้าหลัก',
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.home);
                    },
                  ),
                  
                  _buildSimpleMenuItem(
                    icon: Icons.pets,
                    activeIcon: Icons.pets,
                    title: 'ข้อมูลสุนัขของคุณ',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.dogProfiles);
                    },
                  ),

                  _buildDivider(),
                  
                  // การเรียนรู้
                  _buildSectionTitle('การเรียนรู้'),
                  
                  _buildSimpleMenuItem(
                    icon: Icons.school_outlined,
                    activeIcon: Icons.school,
                    title: 'บทเรียนของฉัน',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.myCourses);
                    },
                  ),
                  
                  _buildSimpleMenuItem(
                    icon: Icons.menu_book_outlined,
                    activeIcon: Icons.menu_book,
                    title: 'บทเรียนทั้งหมด',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.courses);
                    },
                  ),

                  _buildDivider(),
                  
                  // ชุมชนและแชท
                  _buildSectionTitle('ชุมชนและผู้ช่วย'),

                  _buildSimpleMenuItem(
                    icon: Icons.groups_outlined,
                    activeIcon: Icons.groups,
                    title: 'ชุมชน',
                    subtitle: 'แชร์ประสบการณ์กับเพื่อนๆ',
                    requiresAuth: true,
                    onTap: () {
                      if (user != null) {
                        Navigator.pushNamed(context, AppRoutes.community);
                      } else {
                        _showLoginRequiredDialog(context, 'ชุมชน');
                      }
                    },
                  ),

                  _buildSimpleMenuItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    title: 'แชทบอทสุนัข',
                    subtitle: 'ถามคำถามเกี่ยวกับสุนัข',
                    requiresAuth: true,
                    onTap: () {
                      if (user != null) {
                        Navigator.pushNamed(context, AppRoutes.chat);
                      } else {
                        _showLoginRequiredDialog(context, 'แชทบอท');
                      }
                    },
                  ),

                  if (user != null)
                    _buildSimpleMenuItem(
                      icon: Icons.history_outlined,
                      activeIcon: Icons.history,
                      title: 'ประวัติการสนทนา',
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.chatHistory);
                      },
                    ),

                  _buildDivider(),

                  // เครื่องมือฝึกสุนัข
                  _buildSectionTitle('เครื่องมือฝึกสุนัข'),
                  
                  _buildSimpleMenuItem(
                    icon: Icons.touch_app_outlined,
                    activeIcon: Icons.touch_app,
                    title: 'คลิกเกอร์',
                    subtitle: 'เครื่องมือฝึกด้วยเสียง',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.clicker);
                    },
                  ),
                  
                  _buildSimpleMenuItem(
                    icon: Icons.volume_up_outlined,
                    activeIcon: Icons.volume_up,
                    title: 'นกหวีด',
                    subtitle: 'เครื่องมือเรียกสุนัข',
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.whistle);
                    },
                  ),

                  _buildDivider(),
                  
                  // การจัดการบัญชี
                  StreamBuilder<User?>(
                    stream: _auth.authStateChanges(),
                    builder: (context, snapshot) {
                      final user = snapshot.data;
                      
                      if (user == null) {
                        return _buildSimpleMenuItem(
                          icon: Icons.login_outlined,
                          activeIcon: Icons.login,
                          title: 'เข้าสู่ระบบ',
                          subtitle: 'ใช้งานฟีเจอร์เพิ่มเติม',
                          onTap: () {
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                        );
                      } else {
                        return _buildSimpleMenuItem(
                          icon: Icons.logout_outlined,
                          activeIcon: Icons.logout,
                          title: 'ออกจากระบบ',
                          subtitle: user.email ?? '',
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        );
                      }
                    },
                  ),

                  // ข้อมูลเวอร์ชัน
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Doggy Training v1.0.0',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: surfaceColor,
            child: CircleAvatar(
              radius: 32,
              backgroundImage: AssetImage('assets/images/dog_profile.jpg'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'ไม่ได้เข้าสู่ระบบ',
            style: TextStyle(
              color: surfaceColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'กรุณาล็อกอินเพื่อดูโปรไฟล์สุนัข',
            style: TextStyle(
              color: surfaceColor.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(User user) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: FutureBuilder<QuerySnapshot>(
        future: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('dogs')
            .limit(1)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: surfaceColor,
                    child: CircleAvatar(
                      radius: 32,
                      backgroundImage: AssetImage('assets/images/dog_profile.jpg'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName ?? user.email ?? 'ผู้ใช้',
                    style: TextStyle(
                      color: surfaceColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'กรุณาเพิ่มสุนัขของคุณ',
                    style: TextStyle(
                      color: surfaceColor.withOpacity(0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          final dogData = snapshot.data!.docs.first.data() as Map<String, dynamic>;
          final String imageRaw = dogData['image'] ?? '';
          ImageProvider profileImage;

          if (imageRaw.isNotEmpty) {
            if (imageRaw.startsWith('http')) {
              profileImage = NetworkImage(imageRaw);
            } else {
              try {
                profileImage = MemoryImage(base64Decode(imageRaw));
              } catch (e) {
                profileImage = const AssetImage('assets/images/dog_profile.jpg');
              }
            }
          } else {
            profileImage = const AssetImage('assets/images/dog_profile.jpg');
          }

          return Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: surfaceColor,
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: profileImage,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  dogData['name'] ?? 'ไม่ระบุ',
                  style: TextStyle(
                    color: surfaceColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '🐶 โปรไฟล์สุนัขของคุณ',
                  style: TextStyle(
                    color: surfaceColor.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSimpleMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    String? subtitle,
    bool requiresAuth = false,
    required VoidCallback onTap,
  }) {
    final user = _auth.currentUser;
    final showLoginBadge = requiresAuth && user == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 22,
                      ),
                    ),
                    if (showLoginBadge)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.red[600],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: surfaceColor, width: 1),
                          ),
                          child: const Center(
                            child: Text(
                              '!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Login badge for auth required items
              if (showLoginBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 10,
                      color: surfaceColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 1,
      color: Colors.grey[200],
    );
  }

  // Dialog แจ้งเตือนให้ login สำหรับฟีเจอร์ที่ต้องการ authentication
  void _showLoginRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.login_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ต้องเข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'กรุณาเข้าสู่ระบบก่อนใช้งาน$feature',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout,
                  size: 40,
                  color: Colors.red[600],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'คุณต้องการออกจากระบบหรือไม่',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ข้อมูลในเครื่องจะถูกลบออก',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: const Text(
                      'ยกเลิก',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:                   ElevatedButton(
                    onPressed: () async {
                      try {
                        // ใช้ UserService สำหรับการ logout
                        await _userService.logout();
                        // ปิด dialog
                        Navigator.pop(context);
                        // ไปที่หน้า login
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      } catch (e) {
                        // แสดง error ถ้าเกิดข้อผิดพลาด
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'ออกจากระบบ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}