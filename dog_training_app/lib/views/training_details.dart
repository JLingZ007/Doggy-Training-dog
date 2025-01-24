import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingDetailsPage extends StatelessWidget {
  final String documentId; // รับ Document ID จากหน้าก่อนหน้า

  TrainingDetailsPage({required this.documentId});

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ฟังก์ชันดึงข้อมูลรายละเอียดการฝึก
  Future<Map<String, dynamic>> fetchTrainingDetails() async {
    try {
      print('Fetching document: $documentId');
      final snapshot = await _firestore
          .collection('training_categories') // คอลเลกชันหลัก
          .doc('basic_training') // ระบุหมวดหมู่ (Document ID)
          .collection('programs') // Subcollection ของหมวดหมู่
          .doc(documentId) // Document ID ของบทเรียน
          .get();

      if (snapshot.exists) {
        print('Document data: ${snapshot.data()}');
        return snapshot.data() as Map<String, dynamic>;
      } else {
        print('Document not found.');
        throw Exception('Document not found.');
      }
    } catch (e) {
      print('Error: $e');
      throw Exception('Failed to fetch details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'รายละเอียดการฝึก',
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
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchTrainingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No details available.'));
          }

          final details = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แสดงรูปภาพ
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    details['image'] ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/default_image.png', // รูปภาพสำรอง
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // ชื่อการฝึก
                Text(
                  details['name'] ?? 'ไม่มีชื่อการฝึก',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // คำอธิบาย
                Text(
                  details['description'] ?? 'ไม่มีคำอธิบาย',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

                // ระดับความยากและระยะเวลา
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ความยาก: ${details['difficulty'] ?? 'ไม่ระบุ'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'ระยะเวลา: ${details['duration'] ?? 'ไม่ระบุ'} นาที',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ขั้นตอนการฝึก
                Text(
                  'ขั้นตอนการฝึก:',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: details['steps']?.length ?? 0,
                    itemBuilder: (context, index) {
                      final step = details['steps'][index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'ขั้นตอนที่ ${index + 1}: $step',
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
