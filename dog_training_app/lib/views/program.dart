import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';

class TrainingProgramsPage extends StatelessWidget {
  final String categoryId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TrainingProgramsPage({required this.categoryId});

  Future<List<Map<String, dynamic>>> fetchPrograms() async {
    try {
      final snapshot = await _firestore
          .collection('training_categories')
          .doc(categoryId)
          .collection('programs')
          .get();
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch programs: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '📋 รายละเอียดหมวดหมู่',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      drawer: SlideBar(),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('❌ ไม่มีโปรแกรมในหมวดหมู่นี้', style: TextStyle(fontSize: 18, color: Colors.red)));
          }

          final programs = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                childAspectRatio: 0.75, // ปรับให้รูปสมดุลขึ้น
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12, 
              ),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];

                return GestureDetector(
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
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: Colors.brown.withOpacity(0.3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 📌 ส่วนแสดงภาพ (เต็มพื้นที่)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              program['image'] ?? '',
                              width: double.infinity,
                              fit: BoxFit.cover, // ✅ ทำให้ภาพเต็มพื้นที่
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      Text(
                                        'ไม่พบรูปภาพ',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // 📌 ชื่อโปรแกรมฝึก
                              Text(
                                program['name'] ?? 'ไม่มีชื่อโปรแกรม',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
                              ),

                              const SizedBox(height: 8),

                              // 📌 ปุ่มเข้าสู่การฝึก
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes.trainingDetails,
                                    arguments: {
                                      'documentId': program['id'],
                                      'categoryId': categoryId,
                                    },
                                  );
                                },
                                icon: const Icon(Icons.play_circle_fill, size: 18),
                                label: const Text('เข้าสู่การฝึก'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown[300],
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
