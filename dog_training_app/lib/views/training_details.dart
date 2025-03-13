import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId; // รับ Document ID จากหน้าก่อนหน้า

  TrainingDetailsPage({required this.documentId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late YoutubePlayerController _controller;
  bool _isCompleted = false;

  Future<Map<String, dynamic>> fetchTrainingDetails() async {
    try {
      final snapshot = await _firestore
          .collection('training_categories')
          .doc('basic_training')
          .collection('programs')
          .doc(widget.documentId)
          .get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        throw Exception('Document not found.');
      }
    } catch (e) {
      throw Exception('Failed to fetch details: $e');
    }
  }

  // ฟังก์ชันบันทึกคอร์สเรียนของผู้ใช้
  Future<void> _completeCourse(Map<String, dynamic> details) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userCourseRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('my_courses')
        .doc(widget.documentId);

    await userCourseRef.set({
      'name': details['name'],
      'image': details['image'],
      'status': 'completed', // สถานะที่แสดงใน "คอร์สเรียนของฉัน"
      'completedAt': FieldValue.serverTimestamp(),
    });

    setState(() {
      _isCompleted = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกคอร์สเรียนเรียบร้อย!')),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context),
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
          _controller = YoutubePlayerController(
            initialVideoId: YoutubePlayer.convertUrlToId(details['video']) ?? '',
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.amber,
                ),
                const SizedBox(height: 16),

                Text(
                  details['name'] ?? 'ไม่มีชื่อการฝึก',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  details['description'] ?? 'ไม่มีคำอธิบาย',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),

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

                Text(
                  'ขั้นตอนการฝึก:',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                const SizedBox(height: 16),

                // ปุ่มสิ้นสุดบทเรียน
                ElevatedButton(
                  onPressed: _isCompleted ? null : () => _completeCourse(details),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCompleted ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    _isCompleted ? 'คอร์สนี้เสร็จสมบูรณ์แล้ว' : 'สิ้นสุดบทเรียน',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
