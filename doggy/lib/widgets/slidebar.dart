// widgets/slide_bar.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../routes/app_routes.dart';
import '../services/user_service.dart';

/// ---------- Image helpers (ไม่กะพริบ) ----------
String normalizeRaw(String? raw) {
  final r = (raw ?? '').trim();
  if (r.isEmpty || r.toLowerCase() == 'null') return '';
  return r;
}

class StableAvatar extends StatefulWidget {
  const StableAvatar({
    Key? key,
    required this.raw,                 // url / base64 / data-url / '' 
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
    if (oldWidget.raw != widget.raw) {
      _updateIfNeeded(widget.raw);
    }
  }

  void _updateIfNeeded(String rawIn) {
    String raw = normalizeRaw(rawIn);

    // data:image/...;base64,xxxx
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

    // base64 ทุกความยาว
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

/// ---------- SlideBar ----------
class SlideBar extends StatefulWidget {
  const SlideBar({super.key});

  @override
  State<SlideBar> createState() => _SlideBarState();
}

class _SlideBarState extends State<SlideBar> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // Color scheme
  static const Color primaryColor   = Color(0xFFD2B48C);
  static const Color accentColor    = Color(0xFF8B4513);
  static const Color secondaryColor = Color(0xFFC19A5B);
  static const Color surfaceColor   = Colors.white;
  static const Color textPrimary    = Color(0xFF5D4037);
  static const Color textSecondary  = Color(0xFF8D6E63);

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<User?>(
          stream: _auth.authStateChanges(),
          builder: (context, authSnap) {
            final user = authSnap.data;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                (user == null || user.isAnonymous)
                    ? _buildGuestHeader(context)
                    : _buildUserHeader(user),

                // ------- MENU -------
                Container(
                  color: surfaceColor,
                  child: Column(
                    children: [
                      _buildSimpleMenuItem(
                        icon: Icons.home,
                        activeIcon: Icons.home,
                        title: 'หน้าหลัก',
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.home),
                      ),
                      _buildSimpleMenuItem(
                        icon: Icons.pets,
                        activeIcon: Icons.pets,
                        title: 'ข้อมูลสุนัขของคุณ',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                      ),
                      

                      _buildDivider(),

                      _buildSectionTitle('การเรียนรู้'),
                      _buildSimpleMenuItem(
                        icon: Icons.school_outlined,
                        activeIcon: Icons.school,
                        title: 'บทเรียนของฉัน',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.myCourses),
                      ),
                      _buildSimpleMenuItem(
                        icon: Icons.menu_book_outlined,
                        activeIcon: Icons.menu_book,
                        title: 'บทเรียนทั้งหมด',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.courses),
                      ),

                      _buildDivider(),

                      _buildSectionTitle('ชุมชนและผู้ช่วย'),
                      _buildSimpleMenuItem(
                        icon: Icons.groups_outlined,
                        activeIcon: Icons.groups,
                        title: 'ชุมชน',
                        subtitle: 'แชร์ประสบการณ์กับเพื่อนๆ',
                        requiresAuth: true,
                        onTap: () {
                          final u = _auth.currentUser;
                          if (u != null && !u.isAnonymous) {
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
                          final u = _auth.currentUser;
                          if (u != null && !u.isAnonymous) {
                            Navigator.pushNamed(context, AppRoutes.chat);
                          } else {
                            _showLoginRequiredDialog(context, 'แชทบอท');
                          }
                        },
                      ),
                      if (user != null && !user.isAnonymous)
                        _buildSimpleMenuItem(
                          icon: Icons.history_outlined,
                          activeIcon: Icons.history,
                          title: 'ประวัติการสนทนา',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.chatHistory),
                        ),

                      _buildDivider(),

                      _buildSectionTitle('เครื่องมือฝึกสุนัข'),
                      _buildSimpleMenuItem(
                        icon: Icons.touch_app_outlined,
                        activeIcon: Icons.touch_app,
                        title: 'คลิกเกอร์',
                        subtitle: 'เครื่องมือฝึกด้วยเสียง',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.clicker),
                      ),
                      _buildSimpleMenuItem(
                        icon: Icons.volume_up_outlined,
                        activeIcon: Icons.volume_up,
                        title: 'นกหวีด',
                        subtitle: 'เครื่องมือเรียกสุนัข',
                        onTap: () => Navigator.pushNamed(context, AppRoutes.whistle),
                      ),

                      _buildDivider(),
                      if (user == null || user.isAnonymous)
                        _buildSimpleMenuItem(
                          icon: Icons.login_outlined,
                          activeIcon: Icons.login,
                          title: 'เข้าสู่ระบบ',
                          subtitle: 'ใช้งานฟีเจอร์เพิ่มเติม',
                          onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                        )
                      else
                        _buildSimpleMenuItem(
                          icon: Icons.logout_outlined,
                          activeIcon: Icons.logout,
                          title: 'ออกจากระบบ',
                          subtitle: user.email ?? '',
                          onTap: () => _showLogoutDialog(context),
                        ),

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
            );
          },
        ),
      ),
    );
  }

  // ---------- Headers ----------

  Widget _buildGuestHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: surfaceColor,
                child: const StableAvatar(
                  raw: '',
                  placeholder: AssetImage('assets/images/dog_profile.jpg'),
                  radius: 32,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'ไม่ได้เข้าสู่ระบบ',
                style: TextStyle(
                  color: surfaceColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'กรุณาล็อกอินเพื่อใช้งานครบทุกฟีเจอร์',
                style: TextStyle(
                  color: surfaceColor.withOpacity(0.85),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: surfaceColor,
                  foregroundColor: textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.login),
                label: const Text('เข้าสู่ระบบ', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserHeader(User user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            // ไม่กรอง cache เพื่อให้มีข้อมูลแสดงทันที
            stream: _firestore.collection('users').doc(user.uid).snapshots(),
            builder: (context, userSnap) {
              final fallbackName = user.displayName ?? user.email ?? 'ผู้ใช้';

              if (!userSnap.hasData || !(userSnap.data?.exists ?? false)) {
                return _avatarBlockRaw(
                  raw: '',
                  title: fallbackName,
                  subtitle: 'ยังไม่ได้เลือกสุนัขตัวหลัก',
                  onSwitch: _openSwitchDogSheet,
                );
              }

              final data = userSnap.data!.data() ?? <String, dynamic>{};
              final String? activeDogId = (data['activeDogId'] as String?)?.trim();

              if (activeDogId == null || activeDogId.isEmpty) {
                return _avatarBlockRaw(
                  raw: '',
                  title: fallbackName,
                  subtitle: 'ยังไม่ได้เลือกสุนัขตัวหลัก',
                  onSwitch: _openSwitchDogSheet,
                );
              }

              // ฟัง dogs/{activeDogId} realtime
              return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('dogs')
                    .doc(activeDogId)
                    .snapshots(),
                builder: (context, dogSnap) {
                  String name = fallbackName;
                  String subtitle = '🐶 โปรไฟล์ที่ใช้งานอยู่';
                  String raw = '';

                  if (dogSnap.hasData && (dogSnap.data?.exists ?? false)) {
                    final d = dogSnap.data!.data() ?? <String, dynamic>{};
                    name = (d['name'] ?? name).toString();
                    raw = normalizeRaw(d['image'] as String?);
                  } else if (dogSnap.connectionState == ConnectionState.waiting) {
                    subtitle = 'กำลังโหลดโปรไฟล์สุนัข…';
                  } else if (dogSnap.hasError) {
                    subtitle = 'โหลดโปรไฟล์สุนัขไม่สำเร็จ';
                  }

                  return _avatarBlockRaw(
                    raw: raw,
                    title: name,
                    subtitle: subtitle,
                    onSwitch: _openSwitchDogSheet,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------- Switch Dog BottomSheet ----------
  Future<void> _openSwitchDogSheet() async {
    final u = _auth.currentUser;
    if (u == null || u.isAnonymous) {
      _showLoginRequiredDialog(context, 'สลับโปรไฟล์สุนัข');
      return;
    }

    final dogs = await _userService.listDogsSummary();
    if (dogs.isEmpty) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('ยังไม่มีสุนัข'),
          content: const Text('โปรดเพิ่มสุนัขก่อน จากนั้นจึงเลือกโปรไฟล์ที่ต้องการ'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('ปิด')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.dogProfiles);
              },
              child: const Text('ไปเพิ่มสุนัข'),
            ),
          ],
        ),
      );
      return;
    }

    final activeId = await _userService.getActiveDogId();

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('เลือกโปรไฟล์สุนัข',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dogs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = dogs[i];
                    final id = d['id']!;
                    final name = d['name']!;
                    final image = d['image']!;
                    final isActive = (activeId != null && id == activeId);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: surfaceColor,
                        child: StableAvatar(
                          raw: image, // URL / base64 / ''
                          placeholder: const AssetImage('assets/images/dog_profile.jpg'),
                          radius: 18,
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: isActive
                          ? const Chip(
                              label: Text('ใช้งานอยู่'),
                              backgroundColor: Color(0xFFE5F6E8),
                              side: BorderSide(color: Color(0xFFBFE4C4)),
                            )
                          : ElevatedButton(
                              onPressed: () async {
                                try {
                                  await _userService.switchActiveDog(id);
                                  if (!mounted) return;
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('เปลี่ยนโปรไฟล์เป็น "$name"')),
                                  );
                                  setState(() {}); // refresh header
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('สลับโปรไฟล์ไม่สำเร็จ: $e')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEBC7A6),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                elevation: 0,
                              ),
                              child: const Text('ใช้โปรไฟล์นี้'),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Menu / Utils ----------
  Widget _buildSimpleMenuItem({
    required IconData icon,
    required IconData activeIcon,
    required String title,
    String? subtitle,
    bool requiresAuth = false,
    required VoidCallback onTap,
  }) {
    final user = _auth.currentUser;
    final showLoginBadge = requiresAuth && (user == null || user.isAnonymous);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(child: Icon(icon, color: accentColor, size: 22)),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showLoginBadge)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
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
        style: const TextStyle(
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

  void _showLoginRequiredDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.login_outlined, color: Colors.blue[600], size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('ต้องเข้าสู่ระบบ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          content: const Text('กรุณาเข้าสู่ระบบก่อนใช้งานฟีเจอร์นี้', style: TextStyle(fontSize: 14, height: 1.4)),
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
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text('เข้าสู่ระบบ', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
                child: Icon(Icons.logout, size: 40, color: Colors.red[600]),
              ),
              const SizedBox(height: 16),
              const Text(
                'คุณต้องการออกจากระบบหรือไม่',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ข้อมูลในเครื่องจะถูกลบออก',
                style: TextStyle(fontSize: 12, color: textSecondary),
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
                    child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        await _userService.logout();
                        if (mounted) {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        }
                      } catch (e) {
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('เกิดข้อผิดพลาดในการออกจากระบบ: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text('ออกจากระบบ', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // ---------- Small helpers ----------
  Widget _headerSkeleton() => Row(
        children: const [
          CircleAvatar(radius: 35, backgroundColor: Colors.white),
          SizedBox(width: 12),
          Expanded(child: LinearProgressIndicator(minHeight: 12)),
        ],
      );

  // เวอร์ชันใหม่: รับ raw string แล้วใช้ StableAvatar ภายใน
  Widget _avatarBlockRaw({
    required String raw,
    required String title,
    required String subtitle,
    required VoidCallback onSwitch,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 35,
          backgroundColor: surfaceColor,
          child: StableAvatar(
            raw: raw,
            placeholder: const AssetImage('assets/images/dog_profile.jpg'),
            radius: 32,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: surfaceColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            color: surfaceColor.withOpacity(0.8),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: onSwitch,
          icon: const Icon(Icons.switch_account),
          label: const Text('สลับโปรไฟล์'),
          style: ElevatedButton.styleFrom(
            backgroundColor: surfaceColor,
            foregroundColor: textPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
