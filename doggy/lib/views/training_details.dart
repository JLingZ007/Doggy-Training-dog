import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId;
  final String categoryId;

  TrainingDetailsPage({required this.documentId, required this.categoryId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  YoutubePlayerController? _controller;
  bool _isCompleted = false;
  bool _isLoading = true;
  Map<String, dynamic>? details;
  User? currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;
    if (currentUser != null) {
      checkCompletionStatus();
    }
    fetchTrainingDetails();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  // ฟังก์ชันแปลง URL YouTube ให้เป็น videoId
  String extractVideoId(String url) {
    if (url.contains("watch?v=")) {
      return url.split("watch?v=").last.split("&").first;
    } else if (url.contains("youtu.be/")) {
      return url.split("youtu.be/").last.split("?").first;
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : details == null
              ? const Center(child: Text('ไม่พบข้อมูลบทเรียน'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_controller != null)
                        YoutubePlayerBuilder(
                          player: YoutubePlayer(controller: _controller!),
                          builder: (context, player) {
                            return Column(
                              children: [player],
                            );
                          },
                        )
                      else
                        const Center(child: Text('ไม่สามารถโหลดวิดีโอได้')),

                      const SizedBox(height: 16),

                      Text(
                        details!['name'] ?? 'ไม่มีชื่อการฝึก',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        details!['description'] ?? 'ไม่มีคำอธิบาย',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ความยาก: ${details!['difficulty'] ?? 'ไม่ระบุ'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            'ระยะเวลา: ${details!['duration'] ?? 'ไม่ระบุ'} นาที',
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
                          itemCount: details!['steps']?.length ?? 0,
                          itemBuilder: (context, index) {
                            final step = details!['steps'][index];
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

                      // แสดงปุ่ม "สิ้นสุดบทเรียน" เฉพาะผู้ที่ล็อกอินเท่านั้น
                      if (currentUser != null)
                        ElevatedButton(
                          onPressed: _isCompleted ? null : completeCourse,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCompleted ? Colors.grey : Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _isCompleted ? 'บทเรียนนี้เรียนจบแล้ว' : 'สิ้นสุดบทเรียน',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }
}