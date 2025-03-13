import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
        title: const Text('คอร์สเรียนของฉัน'),
        backgroundColor: Colors.brown[200],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .doc(user.uid)
            .collection('my_courses')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = snapshot.data!.docs;

          if (courses.isEmpty) {
            return const Center(child: Text('ยังไม่มีคอร์สที่เรียนจบ'));
          }

          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: Image.network(course['image'], width: 60, height: 60, fit: BoxFit.cover),
                  title: Text(course['name']),
                  subtitle: const Text('สถานะ: ✅ เรียนจบแล้ว'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
