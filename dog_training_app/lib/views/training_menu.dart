import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_detail.dart';

class TrainingMenuPage extends StatelessWidget {
  final String courseId;
  final String courseName;

  const TrainingMenuPage(
      {Key? key, required this.courseId, required this.courseName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(courseName),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('course_types')
            .doc(courseId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ไม่มีข้อมูลบทเรียน'));
          }

          final courseData = snapshot.data!.data() as Map<String, dynamic>;
          final trainings = courseData['trainings'] as List<dynamic>? ?? [];

          return ListView.builder(
            itemCount: trainings.length,
            itemBuilder: (context, index) {
              final training = trainings[index] as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(training['name'] ?? 'ไม่มีชื่อบทเรียน'),
                  subtitle: Text(training['description'] ?? 'ไม่มีคำอธิบาย'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainingDetailPage(
                          trainingName: training['name'] ?? '',
                          description: training['description'] ?? '',
                          videoUrl: training['video_url'] ?? '',
                          tricks: List<String>.from(training['tricks'] ?? []),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
