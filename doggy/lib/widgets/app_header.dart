import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  AppHeader({
    super.key,
    this.title = 'หน้าหลัก',
    this.backgroundColor = const Color(0xFFD2B48C),
    this.elevation = 0,
    this.titleColor = Colors.black,
  });

  final String title;
  final Color backgroundColor;
  final double elevation;
  final Color titleColor;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Text(title, style: TextStyle(color: titleColor)),
        ],
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        // ยังไม่ล็อกอิน → กดแล้วไปหน้าเข้าสู่ระบบ
        if (user == null || user.isAnonymous)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/images/dog_profile.jpg'),
              ),
            ),
          )
        else
          // ล็อกอินแล้ว → ฟัง users/{uid} เพื่อดู activeDogId แบบ realtime
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              // กำลังโหลด / ไม่มีข้อมูล → แสดง default ไปก่อน (ไม่มี error)
              if (userSnap.connectionState == ConnectionState.waiting ||
                  !userSnap.hasData ||
                  !(userSnap.data?.exists ?? false)) {
                return _avatarButton(
                  context: context,
                  image: const AssetImage('assets/images/dog_profile.jpg'),
                  // กดแล้วไปจัดการสุนัข
                  onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                );
              }

              final userData = userSnap.data!.data(); // อาจเป็น null ก็ต้องกัน
              final activeDogId = userData?['activeDogId'] as String?;

              // ยังไม่ได้เลือกสุนัข → ใช้รูป default
              if (activeDogId == null || activeDogId.isEmpty) {
                return _avatarButton(
                  context: context,
                  image: const AssetImage('assets/images/dog_profile.jpg'),
                  onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                );
              }

              // มี activeDogId → ฟังโปรไฟล์น้องหมาแบบ realtime
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('dogs')
                    .doc(activeDogId)
                    .snapshots(),
                builder: (context, dogSnap) {
                  ImageProvider avatar =
                      const AssetImage('assets/images/dog_profile.jpg');

                  if (dogSnap.hasData && (dogSnap.data?.exists ?? false)) {
                    final dogData = dogSnap.data!.data();
                    final raw = (dogData?['image'] ?? '').toString();
                    avatar = _imageFromDog(raw);
                  }

                  return _avatarButton(
                    context: context,
                    image: avatar,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                  );
                },
              );
            },
          ),
      ],
    );
  }

  /// ปุ่มรูป Avatar มุมขวา
  Widget _avatarButton({
    required BuildContext context,
    required ImageProvider image,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(backgroundImage: image),
      ),
    );
  }

  /// สร้าง ImageProvider จากสตริงรูป (รองรับ URL/BASE64/ค่าว่าง)
  ImageProvider _imageFromDog(String raw) {
    if (raw.isEmpty) {
      return const AssetImage('assets/images/dog_profile.jpg');
    }
    if (raw.startsWith('http')) {
      return NetworkImage(raw);
    }
    // เดาว่า base64 ถ้ายาว ๆ
    if (raw.length > 80) {
      try {
        return MemoryImage(base64Decode(raw));
      } catch (_) {
        // เผื่อ base64 เสีย
        return const AssetImage('assets/images/dog_profile.jpg');
      }
    }
    // เผื่อรูปแบบอื่น ๆ → fallback
    return const AssetImage('assets/images/dog_profile.jpg');
  }
}
