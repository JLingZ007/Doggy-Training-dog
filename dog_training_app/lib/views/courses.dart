import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/slidebar.dart';
import '../widgets/bottom_navbar.dart';
import '../routes/app_routes.dart';

class CoursesPage extends StatelessWidget {

  int _currentIndex = 0; // ตัวแปรสำหรับเก็บสถานะหน้าปัจจุบัน
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  

  // ฟังก์ชันดึงข้อมูลคอร์สจาก Firestore
  Future<List<Map<String, dynamic>>> fetchCourses() async {
    try {
      final snapshot = await _firestore.collection('training_programs').get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch courses: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'การฝึกพื้นฐาน',
          style: TextStyle(color: Colors.black),
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
      drawer: SlideBar(), // เพิ่ม SlideBar
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCourses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No courses found.'));
          }

          final courses = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // แสดง 2 คอลัมน์
                childAspectRatio: 0.8, // อัตราส่วนของ Grid แต่ละช่อง
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Image.network(
                          course['image'] ?? '',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          course['name'] ?? 'No Name',
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
                            arguments: course['id'], // ส่ง documentId ไปใน arguments
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
      // bottomNavigationBar: BottomNavBar(
      //   currentIndex: _currentIndex, // สถานะของหน้าปัจจุบัน
      //   onTap: _onNavBarTap, // Callback สำหรับเปลี่ยนหน้า
      // ),
    );
  }
}
