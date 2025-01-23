import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingDetailsPage extends StatelessWidget {
  final String documentId; // รับ ID ของ Document

  const TrainingDetailsPage({Key? key, required this.documentId})
      : super(key: key);

  Future<Map<String, dynamic>> fetchTrainingDetails() async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final docSnapshot =
        await firestore.collection('training_programs').doc(documentId).get();

    if (docSnapshot.exists) {
      return docSnapshot.data()!;
    } else {
      throw Exception('Document not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการฝึก'),
        backgroundColor: Colors.brown[200],
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchTrainingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No details found.'));
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data['description'] ?? 'No Description',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (data['steps'] != null) ...[
                  const Text(
                    'Steps:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...List<Widget>.from((data['steps'] as List).map((step) {
                    return Text(
                      '- $step',
                      style: const TextStyle(fontSize: 16),
                    );
                  })),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
