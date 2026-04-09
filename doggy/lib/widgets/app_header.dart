import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBgColor      = Color(0xFFF7EFE7);
const _kSurfaceCream = Color(0xFFEFE2D3);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);

/// แปลงสตริงรูปให้เป็นรูปแบบที่พร้อมใช้งาน
String normalizeRaw(String? raw) {
  final r = (raw ?? '').trim();
  if (r.isEmpty || r.toLowerCase() == 'null') return '';
  return r;
}

// ─── StableAvatar (ไม่เปลี่ยน logic) ────────────────────────────────────────
class StableAvatar extends StatefulWidget {
  const StableAvatar({
    super.key,
    required this.raw,
    required this.placeholder,
    this.radius = 18,
  });

  final String raw;
  final ImageProvider placeholder;
  final double radius;

  @override
  State<StableAvatar> createState() => _StableAvatarState();
}

class _StableAvatarState extends State<StableAvatar> {
  ImageProvider? _fg;
  String _lastEffectiveRaw = '';

  @override
  void initState() {
    super.initState();
    _updateIfNeeded(widget.raw);
  }

  @override
  void didUpdateWidget(covariant StableAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.raw != widget.raw) _updateIfNeeded(widget.raw);
  }

  void _updateIfNeeded(String rawIn) {
    String raw = normalizeRaw(rawIn);
    if (raw.startsWith('data:image')) {
      final comma = raw.indexOf(',');
      if (comma != -1) raw = raw.substring(comma + 1);
    }
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
    try {
      _fg = MemoryImage(base64Decode(raw));
    } catch (_) {
      _fg = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundImage: widget.placeholder,
      foregroundImage: _fg,
    );
  }
}

// ─── AppHeader ────────────────────────────────────────────────────────────────
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title = 'หน้าหลัก',
    this.backgroundColor = _kSurfaceCream,
    this.elevation = 0,
    this.titleColor = _kDarkBrown,
    this.onDogChanged,
  });

  final String title;
  final Color backgroundColor;
  final double elevation;
  final Color titleColor;
  final VoidCallback? onDogChanged;

  // ✅ ลบ field _auth และ _firestore ออกจากตรงนี้

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _goToDogProfiles(BuildContext context) async {
    final changed =
        await Navigator.pushNamed(context, AppRoutes.dogProfiles);
    if (changed == true && onDogChanged != null) {
      onDogChanged!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ย้ายมาประกาศใน build() แทน
    final auth      = FirebaseAuth.instance;
    final firestore = FirebaseFirestore.instance;
    final user      = auth.currentUser;

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: Icon(Icons.menu_rounded, color: titleColor),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      actions: [
        if (user == null || user.isAnonymous)
          _AvatarButton(
            raw: '',
            onTap: () => Navigator.pushNamed(context, AppRoutes.login),
          )
        else
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: firestore  // ✅ ใช้ local variable
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnap) {
              if (!userSnap.hasData ||
                  !(userSnap.data?.exists ?? false)) {
                return _AvatarButton(
                  raw: '',
                  onTap: () => _goToDogProfiles(context),
                );
              }

              final userData    = userSnap.data!.data();
              final activeDogId =
                  (userData?['activeDogId'] as String?)?.trim();

              if (activeDogId == null || activeDogId.isEmpty) {
                return _AvatarButton(
                  raw: '',
                  badge: true,
                  onTap: () => _goToDogProfiles(context),
                );
              }

              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: firestore  // ✅ ใช้ local variable
                    .collection('users')
                    .doc(user.uid)
                    .collection('dogs')
                    .doc(activeDogId)
                    .snapshots(),
                builder: (context, dogSnap) {
                  final raw = dogSnap.hasData &&
                          (dogSnap.data?.exists ?? false)
                      ? normalizeRaw(
                          dogSnap.data!.data()?['image'] as String?)
                      : '';

                  return _AvatarButton(
                    raw: raw,
                    onTap: () => _goToDogProfiles(context),
                  );
                },
              );
            },
          ),
      ],
    );
  }
}

// ─── Avatar Button ────────────────────────────────────────────────────────────
class _AvatarButton extends StatelessWidget {
  final String raw;
  final VoidCallback onTap;
  final bool badge;

  const _AvatarButton({
    required this.raw,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar ring
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _kLightPaw, width: 1.5),
              ),
              child: StableAvatar(
                raw: raw,
                placeholder:
                    const AssetImage('assets/images/dog_profiles.png'),
                radius: 17,
              ),
            ),
            // ✅ badge dot เมื่อยังไม่ได้เลือกสุนัข
            if (badge)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE05252),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}