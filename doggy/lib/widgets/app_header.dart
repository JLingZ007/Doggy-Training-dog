import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

/// แปลงสตริงรูปให้เป็นรูปแบบที่พร้อมใช้งาน
String normalizeRaw(String? raw) {
  final r = (raw ?? '').trim();
  if (r.isEmpty || r.toLowerCase() == 'null') return '';
  return r;
}

/// Avatar แบบเสถียร: แปลง raw → ImageProvider เฉพาะตอน raw เปลี่ยนจริง ๆ
class StableAvatar extends StatefulWidget {
  const StableAvatar({
    Key? key,
    required this.raw, // url / base64 / data-url / '' (ว่าง = ไม่มีรูปจริง)
    required this.placeholder,
    this.radius = 18,
  }) : super(key: key);

  final String raw;
  final ImageProvider placeholder;
  final double radius;

  @override
  State<StableAvatar> createState() => _StableAvatarState();
}

class _StableAvatarState extends State<StableAvatar> {
  ImageProvider? _fg; // real image (memoized)
  String _lastEffectiveRaw = '';

  @override
  void initState() {
    super.initState();
    _updateIfNeeded(widget.raw);
  }

  @override
  void didUpdateWidget(covariant StableAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.raw != widget.raw) {
      _updateIfNeeded(widget.raw);
    }
  }

  void _updateIfNeeded(String rawIn) {
    String raw = normalizeRaw(rawIn);

    // รองรับ data URL
    if (raw.startsWith('data:image')) {
      final comma = raw.indexOf(',');
      if (comma != -1) raw = raw.substring(comma + 1); // เอาเฉพาะส่วน base64
    }

    // ถ้าเหมือนเดิมไม่ต้องทำอะไร
    if (_lastEffectiveRaw == raw) return;
    _lastEffectiveRaw = raw;

    if (raw.isEmpty) {
      _fg = null;
      setState(() {});
      return;
    }

    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      _fg = NetworkImage(raw);
      setState(() {});
      return;
    }

    // base64 (ยอมรับทุกความยาว)
    try {
      final bytes = base64Decode(raw);
      _fg = MemoryImage(bytes);
    } catch (_) {
      _fg = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: widget.placeholder, // โชว์ก่อน
      foregroundImage: _fg,                // โหลดเสร็จทับ
    );
  }
}

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
        if (user == null || user.isAnonymous)
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: StableAvatar(
                raw: '',
                placeholder: AssetImage('assets/images/dog_profile.jpg'),
                radius: 18,
              ),
            ),
          )
        else
          // ฟัง users/{uid} (ไม่กรอง cache เพื่อให้มีค่าเสมอ)
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _firestore.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData || !(userSnap.data?.exists ?? false)) {
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: StableAvatar(
                      raw: '',
                      placeholder: AssetImage('assets/images/dog_profile.jpg'),
                      radius: 18,
                    ),
                  ),
                );
              }

              final userData = userSnap.data!.data();
              final activeDogId = (userData?['activeDogId'] as String?)?.trim();

              if (activeDogId == null || activeDogId.isEmpty) {
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: StableAvatar(
                      raw: '',
                      placeholder: AssetImage('assets/images/dog_profile.jpg'),
                      radius: 18,
                    ),
                  ),
                );
              }

              // ฟัง dogs/{activeDogId} (ไม่กรอง cache)
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('dogs')
                    .doc(activeDogId)
                    .snapshots(),
                builder: (context, dogSnap) {
                  String raw = '';
                  if (dogSnap.hasData && (dogSnap.data?.exists ?? false)) {
                    raw = normalizeRaw(dogSnap.data!.data()?['image'] as String?);
                  }

                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: StableAvatar(
                        raw: raw,
                        placeholder: const AssetImage('assets/images/dog_profile.jpg'),
                        radius: 18,
                      ),
                    ),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}
