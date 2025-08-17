import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class MyCoursesPage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('กรุณาเข้าสู่ระบบก่อน'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('บทเรียนของฉัน', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('progress')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีประวัติการฝึก',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final courses = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final id = courses[index].id; // programId
              final course =
                  courses[index].data() as Map<String, dynamic>? ?? {};
              final name = course['name'] ?? 'ไม่ทราบชื่อ';
              final image = course['image'] ?? '';
              final percent = (course['progressPercent'] ?? 0) as int;
              final total = (course['totalSteps'] ?? 0) as int;
              final currentStep = (course['currentStep'] ?? 1) as int;
              final catId = course['categoryId'] ?? '';

              final isDone = percent >= 100;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                shadowColor: Colors.black26,
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // เข้าไปฝึกต่อ
                    if (catId.toString().isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.trainingDetails,
                        arguments: {
                          'documentId': id,
                          'categoryId': catId,
                        },
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: (image.toString().isNotEmpty)
                              ? Image.network(
                                  image,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _fallbackBox(),
                                )
                              : _fallbackBox(width: 70, height: 70),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: (percent / 100).clamp(0, 1),
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFECECEC),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text('$percent%'),
                                  const Spacer(),
                                  Text('ขั้นที่ $currentStep / $total'),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          isDone ? Icons.check_circle : Icons.play_circle_fill,
                          color: isDone ? Colors.green : Colors.brown[400],
                          size: 26,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _fallbackBox({double width = 70, double height = 70}) => Container(
        width: width,
        height: height,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: Colors.grey),
      );
}
