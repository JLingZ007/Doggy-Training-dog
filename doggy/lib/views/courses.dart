import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';
import '../widgets/bottom_navbar.dart';

class CoursesPage extends StatelessWidget {
  CoursesPage({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงข้อมูลหมวดหมู่จาก Firestore
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('training_categories').get();
      final docs = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // เรียงตาม order (เหมือนเดิม)
      docs.sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));
      return docs;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    const tan = Color(0xFFD2B48C);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: const Text(
          'หมวดหมู่การฝึก',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        backgroundColor: tan,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const SlideBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return const Center(child: Text('ไม่พบหมวดหมู่'));
          }

          // เรียงแบบ 1 แถวต่อการ์ด (compact horizontal card)
          return ListView.separated(
            // แก้ไขปัญหา Overflow #1: เพิ่ม padding ด้านล่างเป็น 80.0
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), 
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final c = categories[i];
              return _CategoryRowCard(
                id: c['id'],
                name: c['name'] ?? 'ไม่มีชื่อ',
                desc: c['description'] ?? '',
                imageUrl: c['image'] ?? '',
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.trainingPrograms,
                    arguments: c['id'],
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

// ===================================================================
// =============== Compact Horizontal Card (1 แถว/การ์ด) ===============
// ===================================================================

class _CategoryRowCard extends StatelessWidget {
  final String id;
  final String name;
  final String desc;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryRowCard({
    required this.id,
    required this.name,
    required this.desc,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const tan = Color(0xFFD2B48C);
    const brown = Color(0xFF8B4513);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          // **แก้ไข Overflow #2: เพิ่มความสูงจาก 110 เป็น 114 เพื่อแก้ปัญหา RenderFlex overflow ใน Column ภายใน**
          height: 114, 
          decoration: BoxDecoration(
            border: Border.all(color: tan.withOpacity(0.35), width: 1),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // รูปด้านซ้าย (มุมโค้ง)
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(14)),
                child: SizedBox(
                  width: 140, // เล็กลงจาก Card เดิม
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _fallbackImage(),
                            )
                          : _fallbackImage(),
                      // overlay ด้านล่างเล็กๆ ให้ชื่ออ่านชัด หากจอแคบ
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.35),
                                Colors.transparent
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // เนื้อหาด้านขวา
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อ (เล็กลง + หนักแน่น)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: brown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (desc.trim().isNotEmpty)
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.25,
                            color: Colors.black.withOpacity(0.75),
                          ),
                        ),
                      const Spacer(),
                      Row(
                        children: [
                          // ปุ่มเล็กแบบ TextButton (ไม่เทอะทะ)
                          TextButton(
                            onPressed: onTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              foregroundColor: Colors.black,
                              backgroundColor: tan.withOpacity(0.35),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: tan.withOpacity(0.75)),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            child: const Text('ดูบทเรียน'),
                          ),
                          const Spacer(),
                          // icon เล็กๆ ให้รู้สึกคลิกเข้าได้
                          IconButton(
                            onPressed: onTap,
                            icon: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: brown),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'เปิดหมวดหมู่',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      color: const Color(0xFFECE7E1),
      child: const Center(
        child: Icon(Icons.image_not_supported, size: 26, color: Colors.grey),
      ),
    );
  }
}

// ===================================================================
// =============== Skeleton แบบ List (โหลดครั้งแรก) ===============
// ===================================================================

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      // ใช้ padding 80 เหมือนกัน
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 80), 
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => _SkeletonRow(),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tan = Color(0xFFD2B48C);
    return Container(
      // **แก้ไข Overflow #2: ใช้ความสูง 114 เหมือน Card จริง**
      height: 114, 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tan.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(14)),
            child: Container(width: 140, color: const Color(0xFFEFEFEF)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                children: [
                  _bar(w: double.infinity, h: 14),
                  const SizedBox(height: 8),
                  _bar(w: double.infinity, h: 10),
                  const SizedBox(height: 6),
                  _bar(w: double.infinity, h: 10),
                  const Spacer(),
                  Row(
                    children: [
                      _bar(w: 82, h: 26, r: 10),
                      const Spacer(),
                      _bar(w: 20, h: 20, r: 10),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _bar({double w = 120, double h = 12, double r = 6}) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: const Color(0xFFEFEFEF),
          borderRadius: BorderRadius.circular(r),
        ),
      );
}