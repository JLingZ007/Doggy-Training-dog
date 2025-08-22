import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId; // รับ Document ID จากหน้าก่อนหน้า
  final String categoryId; // เพิ่ม categoryId สำหรับการดึงข้อมูล

  TrainingDetailsPage({required this.documentId, required this.categoryId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late YoutubePlayerController _controller;

  // ฟังก์ชันดึงข้อมูลรายละเอียดการฝึก
  Future<Map<String, dynamic>> fetchTrainingDetails() async {
    try {
      final snapshot = await _firestore
          .collection('training_categories')
          .doc(widget.categoryId) // ใช้ categoryId
          .collection('programs')
          .doc(widget.documentId) // ใช้ documentId
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

  @override
  void dispose() {
    _controller
        .dispose(); // ต้องแน่ใจว่าได้ลบ YoutubePlayer controller เมื่อไม่ใช้
    super.dispose();
  }

      return url.split("watch?v=").last.split("&").first;
    } else if (url.contains("youtu.be/")) {
    } else if (url.contains("embed/")) {
      return url.split("embed/").last.split("?").first;
    }
    return '';
  }

  // โหลดข้อมูลจาก Firestore และกำหนดตัวควบคุมวิดีโอ
  Future<void> fetchTrainingDetails() async {
    try {
      final snapshot = await _firestore
          .collection('training_categories')
          .doc(widget.categoryId)
          .collection('programs')
          .doc(widget.documentId)
          .get();

      if (!snapshot.exists) {
        throw Exception('Document not found.');
      }

      final data = snapshot.data() as Map<String, dynamic>;
      String videoId = extractVideoId(data['video'] ?? '');

      setState(() {
        details = data;
        _isLoading = false;
        if (videoId.isNotEmpty) {
          _controller = YoutubePlayerController(
            initialVideoId: videoId,
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );
        }
      });
    } catch (e) {
      print('Error fetching details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ตรวจสอบสถานะเรียนจบ
  Future<void> checkCompletionStatus() async {
    if (currentUser == null) return;

    final doc = await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('my_courses')
        .doc(widget.documentId)
        .get();

    if (doc.exists) {
      setState(() {
        _isCompleted = true;
      });
    }
  }

  //บันทึกว่าผู้ใช้เรียนจบ
  Future<void> completeCourse() async {
    if (currentUser == null || details == null) return;

    await _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .collection('my_courses')
        .doc(widget.documentId)
        .set({
      'name': details!['name'],
      'image': details!['image'],
      'category': widget.categoryId,
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการฝึก', style: TextStyle(color: Colors.black)),
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

          // สร้าง YoutubePlayerController จาก URL ที่เก็บใน Firestore
          _controller = YoutubePlayerController(
            initialVideoId:
                YoutubePlayer.convertUrlToId(details['video']) ?? '',
            flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
          );

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // แสดงวิดีโอจาก YouTube
                YoutubePlayer(
                  controller: _controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.amber,
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

                Text(
                  'ขั้นตอนการฝึก: ',
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
                      final step =
                          details['steps'][index]; // รับข้อมูลใน array steps
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          'ขั้นตอนที่ ${index + 1}: ${step}',
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
