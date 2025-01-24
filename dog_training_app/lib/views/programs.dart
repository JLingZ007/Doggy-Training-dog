import 'package:dog_training_app/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/slidebar.dart';

class TrainingProgramsPage extends StatelessWidget {
  final String categoryId; // เพิ่มตัวแปร `categoryId`
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor ที่รับ `categoryId`
  TrainingProgramsPage({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันดึงข้อมูล Subcollection ของหมวดหมู่
    Future<List<Map<String, dynamic>>> fetchPrograms() async {
      try {
        final snapshot = await _firestore
            .collection('training_categories')
            .doc(categoryId) // ดึงข้อมูลจาก Document ID (หมวดหมู่)
            .collection('programs') // Subcollection (บทเรียน)
            .get();
        return snapshot.docs
            .map((doc) => {
                  'id': doc.id, // เพิ่ม id ของเอกสาร
                  ...doc.data(),
                })
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch programs: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('หมวดหมู่: $categoryId'), // แสดง `categoryId`
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
            return const Center(child: Text('ไม่มีบทเรียนในหมวดหมู่นี้.'));
          }

          final programs = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // แสดง 2 คอลัมน์
                childAspectRatio: 0.8, // อัตราส่วนของ Grid แต่ละช่อง
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                final program = programs[index];
                return Card(
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
                          program['image'] ?? '',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              'assets/images/default_image.png', // Placeholder
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          program['name'] ?? 'ไม่มีชื่อบทเรียน',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.trainingDetails,
                            arguments:
                                program['id'], // ส่ง Document ID ของโปรแกรมไป
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('เข้าสู่การฝึก'),
                      ),
                    ],
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
