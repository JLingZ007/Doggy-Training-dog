import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'training_menu.dart';

class TrainingTypePage extends StatelessWidget {
  const TrainingTypePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หมวดหมู่การฝึก'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('course_types').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ไม่มีข้อมูลการฝึก'));
          }

          final courseTypes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: courseTypes.length,
            itemBuilder: (context, index) {
              final data = courseTypes[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(
                    data['name'] ?? 'ไม่มีชื่อหมวดหมู่',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(data['description'] ?? 'ไม่มีคำอธิบาย'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrainingMenuPage(
                          courseId: courseTypes[index].id,
                          courseName: data['name'] ?? '',
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
