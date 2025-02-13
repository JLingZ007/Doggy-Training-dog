import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId; // รับ Document ID จากหน้าก่อนหน้า

  TrainingDetailsPage({required this.documentId});

  @override
  _TrainingDetailsPageState createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late YoutubePlayerController _controller;

  // ฟังก์ชันดึงข้อมูลรายละเอียดการฝึก
  Future<Map<String, dynamic>> fetchTrainingDetails() async {
    try {
      print('Fetching document: ${widget.documentId}');
      final snapshot = await _firestore
          .collection('training_categories')
          .doc('basic_training')
          .collection('programs')
          .doc(widget.documentId)
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
  void dispose() {
    _controller.dispose();  // ต้องแน่ใจว่าได้ลบ YoutubePlayer controller เมื่อไม่ใช้
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
            initialVideoId: YoutubePlayer.convertUrlToId(details['video']) ?? '',
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

                // ขั้นตอนการฝึก
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
