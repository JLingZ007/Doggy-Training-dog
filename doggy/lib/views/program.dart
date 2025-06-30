import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';


class TrainingProgramsPage extends StatelessWidget {
  final String categoryId; // รับ ID ของหมวดหมู่
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Constructor
  TrainingProgramsPage({required this.categoryId});

  @override
  Widget build(BuildContext context) {
    // ฟังก์ชันดึงข้อมูล Subcollection ของหมวดหมู่
    Future<List<Map<String, dynamic>>> fetchPrograms() async {
      try {
        final snapshot = await _firestore
            .collection('training_categories')
            .doc(categoryId) // Document ID ของหมวดหมู่
            .collection('programs') // Subcollection (โปรแกรมการฝึก)
            .get();
        return snapshot.docs
            .map((doc) => {
                  'id': doc.id, // Document ID
                  ...doc.data(),
                })
            .toList();
      } catch (e) {
        throw Exception('Failed to fetch programs: $e');
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดหมวดหมู่',
            style: TextStyle(color: Colors.black)),
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
        future: fetchPrograms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('ไม่มีโปรแกรมในหมวดหมู่นี้'));
          }

          final programs = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
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
                              'assets/images/default_image.png',
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
                          program['name'] ?? 'ไม่มีชื่อโปรแกรม',
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
                            arguments: {
                              'documentId': program['id'], // ส่ง Document ID
                              'categoryId': categoryId, // ส่ง Category ID
                            },
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