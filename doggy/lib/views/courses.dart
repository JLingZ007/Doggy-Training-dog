import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';
import '../widgets/bottom_navbar.dart';

class CoursesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ฟังก์ชันดึงข้อมูลหมวดหมู่จาก Firestore
  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final snapshot = await _firestore.collection('training_categories').get();
      final docs = snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      docs.sort((a, b) => (a['order'] ?? 999).compareTo(b['order'] ?? 999));

      return docs;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'หมวดหมู่การฝึก',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFD2B48C),
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
        future: fetchCategories(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No categories found.'));
          }

          final categories = snapshot.data!;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          category['image'] ?? '',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // แสดงภาพเริ่มต้นถ้าภาพไม่สามารถโหลดได้
                            return Image.asset(
                              'assets/images/default_image.png',
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category['name'] ?? 'ไม่มีชื่อหมวดหมู่',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              category['description'] ?? 'ไม่มีคำอธิบาย',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRoutes
                                        .trainingPrograms, // ชื่อต้องตรงกับใน AppRoutes
                                    arguments:
                                        category['id'], // ส่ง id ของหมวดหมู่
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFD2B48C),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('ดูบทเรียน'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1, // หน้าหลัก
      ),
    );
  }
}
