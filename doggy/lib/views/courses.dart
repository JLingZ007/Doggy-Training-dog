import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';
import '../widgets/bottom_navbar.dart';

class CoursesPage extends StatelessWidget {
  CoursesPage({super.key});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final snapshot = await _firestore.collection('training_categories').get();

    final docs = snapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data(),
            })
        .toList();

    docs.sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));

    return docs;
  }

  @override
  Widget build(BuildContext context) {
    const tan = Color(0xFFD2B48C);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F1EA),
      drawer: const SlideBar(),
      appBar: AppBar(
        title: const Text(
          'หมวดหมู่การฝึก',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        backgroundColor: tan,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _ListSkeleton();
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'),
            );
          }

          final categories = snapshot.data ?? [];

          if (categories.isEmpty) {
            return const Center(
              child: Text('ไม่พบหมวดหมู่'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final c = categories[i];

              return _CategoryCard(
                id: c['id'],
                name: c['name'] ?? '',
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

class _CategoryCard extends StatelessWidget {
  final String id;
  final String name;
  final String desc;
  final String imageUrl;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.id,
    required this.name,
    required this.desc,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const tan = Color(0xFFD2B48C);
    const brown = Color(0xFF6B3F1D);

    return Material(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 130,
          child: Row(
            children: [

              /// IMAGE
              ClipRRect(
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(18)),
                child: SizedBox(
                  width: 150,
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

                      /// gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 40,
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
                      )
                    ],
                  ),
                ),
              ),

              /// CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// TITLE
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: brown,
                        ),
                      ),

                      const SizedBox(height: 6),

                      /// DESCRIPTION
                      if (desc.isNotEmpty)
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.black.withOpacity(0.7),
                            height: 1.3,
                          ),
                        ),

                      const Spacer(),

                      /// BUTTON ROW
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: onTap,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: tan,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            child: const Text('ดูบทเรียน'),
                          ),

                          const Spacer(),

                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: brown,
                          ),
                        ],
                      )
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
      color: const Color(0xFFEDE7E0),
      child: const Center(
        child: Icon(Icons.pets, size: 36, color: Colors.grey),
      ),
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 150,
            decoration: const BoxDecoration(
              color: Color(0xFFEFEFEF),
              borderRadius:
                  BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(w: 160, h: 16),
                  const SizedBox(height: 8),
                  _bar(w: double.infinity, h: 10),
                  const SizedBox(height: 6),
                  _bar(w: double.infinity, h: 10),
                  const Spacer(),
                  _bar(w: 90, h: 28, r: 10),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _bar({double w = 120, double h = 12, double r = 6}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(r),
      ),
    );
  }
}