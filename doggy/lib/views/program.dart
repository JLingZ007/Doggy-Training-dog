import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';

class TrainingProgramsPage extends StatelessWidget {
  final String categoryId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrainingProgramsPage({required this.categoryId});

  Future<List<Map<String, dynamic>>> fetchPrograms() async {
    final snapshot = await _firestore
        .collection('training_categories')
        .doc(categoryId)
        .collection('programs')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('รายละเอียดหมวดหมู่', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: SlideBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final programs = snapshot.data ?? [];
          if (programs.isEmpty) {
            return const Center(child: Text('ไม่มีโปรแกรมในหมวดหมู่นี้'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              final crossAxisCount = (maxW >= 900)
                  ? 4
                  : (maxW >= 600)
                      ? 3
                      : 2;

              // คำนวณอัตราส่วนการ์ดใหม่ (ไม่มีปุ่มแล้ว)
              final itemWidth =
                  (maxW - 16 * 2 - 10 * (crossAxisCount - 1)) / crossAxisCount;
              final imageHeight = itemWidth * (10 / 16); // 16:10
              const textArea = 64.0; // ชื่อ + padding
              const verticalPadding = 20.0;
              final itemHeight = imageHeight + textArea + verticalPadding;
              final childAspectRatio = itemWidth / itemHeight;

              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: childAspectRatio,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return _ProgramCard(
                      name: program['name'] ?? 'ไม่มีชื่อโปรแกรม',
                      imageUrl: program['image'] ?? '',
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.trainingDetails,
                          arguments: {
                            'documentId': program['id'],
                            'categoryId': categoryId,
                          },
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProgramCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // รูปภาพ (รักษาสัดส่วน)
            AspectRatio(
              aspectRatio: 16 / 10,
              child: (imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _grayBox(),
                    )
                  : _grayBox(),
            ),
            // ชื่อการฝึก
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grayBox() => Container(
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, size: 40, color: Colors.grey),
      );
}
