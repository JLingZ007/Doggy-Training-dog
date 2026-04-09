import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../routes/app_routes.dart';
import 'add_dog.dart';
import 'edit_dog_profile.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const kBgColor       = Color(0xFFF7EFE7);
const kSurfaceCream  = Color(0xFFEFE2D3);
const kFieldCream    = Color(0xFFEAD8C8);
const kLightPaw      = Color(0xFFE8D5C0);
const kPrimaryBrown  = Color(0xFFB08968);
const kDarkBrown     = Color(0xFF6D4C41);
const kCancelColor   = Color(0xFF7C5959);
const kSuccessGreen  = Color(0xFF4C9A5C);
const kSuccessBg     = Color(0xFFEDF6EE);
const kSuccessBorder = Color(0xFFC3E6CB);

// ─── Responsive helpers ───────────────────────────────────────────────────────
bool   _wide(BuildContext c) => MediaQuery.of(c).size.width >= 600;
double _hPad(BuildContext c) => _wide(c) ? 32.0 : 14.0;

class DogProfilesPage extends StatefulWidget {
  const DogProfilesPage({super.key});

  @override
  State<DogProfilesPage> createState() => _DogProfilesPageState();
}

class _DogProfilesPageState extends State<DogProfilesPage> {
  final _auth        = FirebaseAuth.instance;
  final _firestore   = FirebaseFirestore.instance;
  final _userService = UserService();

  Stream<String?> get _activeDogStream {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((s) => s.data()?['activeDogId'] as String?);
  }

  Future<void> _setActiveDog(String dogId) async {
    await _userService.setActiveDogId(dogId);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _deleteDogProfile(String docId, String dogName) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kLightPaw),
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEECEC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFF5C0C0)),
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 26, color: Color(0xFFD32F2F)),
              ),
              const SizedBox(height: 14),
              const Text('ยืนยันการลบ',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: kDarkBrown)),
              const SizedBox(height: 8),
              Text('ลบโปรไฟล์ของ "$dogName"\nการกระทำนี้ไม่สามารถย้อนกลับได้',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: kPrimaryBrown,
                      height: 1.6, fontWeight: FontWeight.w500)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('ลบโปรไฟล์'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBrown,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users').doc(user.uid)
          .collection('dogs').doc(docId).delete();
      await _userService.clearActiveDogIfDeleted(docId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('ลบโปรไฟล์สุนัขแล้ว'),
        backgroundColor: kPrimaryBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e'),
        backgroundColor: kCancelColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  ImageProvider _buildImage(String? raw) {
    if (raw == null || raw.isEmpty)
      return const AssetImage('assets/images/dog_profiles.png');
    if (raw.startsWith('http')) return NetworkImage(raw);
    try {
      if (raw.length > 100) return MemoryImage(base64Decode(raw));
    } catch (_) {}
    return const AssetImage('assets/images/dog_profiles.png');
  }

  Widget _buildCard(BuildContext context, QueryDocumentSnapshot doc,
      String? activeDogId) {
    final data     = doc.data() as Map<String, dynamic>;
    final dogId    = doc.id;
    final isActive = activeDogId == dogId;
    return _DogCard(
      data: data, dogId: dogId, isActive: isActive,
      buildImage: _buildImage,
      onSelect: () => _setActiveDog(dogId),
      onEdit: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => EditDogProfilePage(dogData: data, docId: dogId))),
      onDelete: () => _deleteDogProfile(dogId, data['name'] ?? 'สุนัขตัวนี้'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final wide = _wide(context);
    final hPad = _hPad(context);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leadingWidth: 56,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: kSurfaceCream, shape: BoxShape.circle,
                border: Border.all(color: kLightPaw),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: kDarkBrown),
            ),
          ),
        ),
        title: const Text('ข้อมูลสุนัขของคุณ',
            style: TextStyle(color: kDarkBrown, fontWeight: FontWeight.w800,
                fontSize: 16, letterSpacing: -0.2)),
      ),
      body: user == null
          ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
          : StreamBuilder<String?>(
              stream: _activeDogStream,
              builder: (context, activeSnap) {
                final activeDogId = activeSnap.data;
                return Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _firestore
                            .collection('users').doc(user.uid)
                            .collection('dogs').snapshots(),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(
                                color: kPrimaryBrown, strokeWidth: 2.5));
                          }

                          final dogs = snap.data?.docs ?? [];
                          if (dogs.isEmpty) {
                            return _EmptyDogs(onAdd: () => Navigator.push(
                                context, MaterialPageRoute(
                                    builder: (_) => const AddDogPage())));
                          }

                          // ── Phone: ListView / Tablet: 2-col GridView ──
                          if (!wide) {
                            return ListView.builder(
                              padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                              itemCount: dogs.length,
                              itemBuilder: (ctx, i) =>
                                  _buildCard(ctx, dogs[i], activeDogId),
                            );
                          }
                          return GridView.builder(
                            padding: EdgeInsets.fromLTRB(hPad, 14, hPad, 0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              childAspectRatio: 1.55,
                            ),
                            itemCount: dogs.length,
                            itemBuilder: (ctx, i) =>
                                _buildCard(ctx, dogs[i], activeDogId),
                          );
                        },
                      ),
                    ),

                    // ── Add button (SafeArea + responsive width) ───────
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 16),
                        child: Center(
                          child: ConstrainedBox(
                            // tablet จำกัดกว้างไม่ให้ button กว้างเกิน
                            constraints: BoxConstraints(
                                maxWidth: wide ? 400 : double.infinity),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(context,
                                    MaterialPageRoute(
                                        builder: (_) => const AddDogPage())),
                                icon: const Icon(Icons.add_rounded, size: 18),
                                label: const Text('เพิ่มสุนัข'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: kDarkBrown,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                  elevation: 0,
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

// ─── Dog Card ─────────────────────────────────────────────────────────────────
class _DogCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String dogId;
  final bool isActive;
  final ImageProvider Function(String?) buildImage;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DogCard({
    required this.data, required this.dogId, required this.isActive,
    required this.buildImage, required this.onSelect,
    required this.onEdit, required this.onDelete,
  });

  String _truncate(String? s, int max) {
    if (s == null || s.isEmpty) return '-';
    return s.length > max ? '${s.substring(0, max - 1)}…' : s;
  }

  @override
  Widget build(BuildContext context) {
    final wide         = _wide(context);
    final avatarRadius = wide ? 32.0 : 28.0;
    final nameFontSize = wide ? 15.0 : 14.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: EdgeInsets.only(bottom: wide ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isActive ? kSuccessBorder : kLightPaw,
            width: isActive ? 1.5 : 1.0),
        boxShadow: [BoxShadow(
            color: kPrimaryBrown.withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: isActive ? null : onSelect,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [

                // ── Avatar + name + menu row ──────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: isActive ? kSuccessBorder : kLightPaw,
                            width: isActive ? 2 : 1.5),
                      ),
                      child: CircleAvatar(
                        radius: avatarRadius,
                        backgroundImage: buildImage(data['image'] as String?),
                        backgroundColor: kFieldCream,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + badge — Wrap ป้องกัน overflow
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6, runSpacing: 4,
                            children: [
                              Text(data['name'] ?? 'ไม่ระบุ',
                                  style: TextStyle(
                                      fontSize: nameFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: kDarkBrown,
                                      letterSpacing: -0.1)),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kSuccessBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: kSuccessBorder),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          size: 11, color: kSuccessGreen),
                                      SizedBox(width: 3),
                                      Text('กำลังติดตาม',
                                          style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: kSuccessGreen)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Chips — Wrap ป้องกันล้นทุกกรณี
                          Wrap(
                            spacing: 6, runSpacing: 5,
                            children: [
                              _InfoChip(Icons.cake_outlined,
                                  'อายุ ${data['age'] ?? '-'}'),
                              _InfoChip(Icons.pets_outlined,
                                  _truncate(data['breed'] as String?, 18)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // More menu
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'select') onSelect();
                        if (val == 'edit')   onEdit();
                        if (val == 'delete') onDelete();
                      },
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      itemBuilder: (_) => [
                        if (!isActive)
                          _mi('select',
                              Icons.check_circle_outline_rounded,
                              'ตั้งเป็นตัวที่ติดตาม', kSuccessGreen),
                        _mi('edit', Icons.edit_outlined,
                            'แก้ไขข้อมูล', kPrimaryBrown),
                        _mi('delete', Icons.delete_outline_rounded,
                            'ลบโปรไฟล์', const Color(0xFFD32F2F)),
                      ],
                      icon: const Icon(Icons.more_vert_rounded,
                          size: 20, color: kPrimaryBrown),
                    ),
                  ],
                ),

                // ── Select button ─────────────────────────────────────
                if (!isActive) ...[
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: onSelect,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: kDarkBrown,
                          borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_rounded,
                              size: 12, color: Colors.white),
                          SizedBox(width: 5),
                          Text('เลือกตัวนี้',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _mi(
      String val, IconData icon, String label, Color color) {
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: color == kPrimaryBrown ? kDarkBrown : color)),
      ]),
    );
  }
}

// ─── Info Chip ─────────────────────────────────────────────────────────────────
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: kSurfaceCream, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: kPrimaryBrown),
          const SizedBox(width: 4),
          // ✅ Flexible ป้องกัน overflow ใน Row แคบ
          Flexible(
            child: Text(label,
                style: const TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: kDarkBrown),
                overflow: TextOverflow.ellipsis, maxLines: 1),
          ),
        ],
      ),
    );
  }
}

// ─── Empty State ───────────────────────────────────────────────────────────────
class _EmptyDogs extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyDogs({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: _hPad(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kSurfaceCream, shape: BoxShape.circle),
              child: const Icon(Icons.pets_rounded,
                  size: 44, color: kPrimaryBrown),
            ),
            const SizedBox(height: 16),
            const Text('ยังไม่มีข้อมูลสุนัข',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800,
                    color: kDarkBrown)),
            const SizedBox(height: 8),
            const Text('เพิ่มสุนัขเพื่อเริ่มติดตามการฝึก',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: kPrimaryBrown,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('เพิ่มสุนัขตัวแรก'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}