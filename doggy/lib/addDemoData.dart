import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addDemoData() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // เพิ่มผู้ใช้
  await _firestore.collection('users').doc('user_123').set({
    'id': 'user_123',
    'name': 'John Doe',
    'email': 'john.doe@gmail.com',
    'profilePicture': 'https://example.com/john_doe.png',
  });

  // เพิ่มสุนัขของผู้ใช้
  final dogsCollection =
      _firestore.collection('users').doc('user_123').collection('dogs');
  await dogsCollection.add({
    'id': 'dog_1',
    'name': 'Buddy',
    'breed': 'Golden Retriever',
    'age': 3,
  });
  await dogsCollection.add({
    'id': 'dog_2',
    'name': 'Max',
    'breed': 'Pomeranian',
    'age': 2,
  });

  // เพิ่มโปรแกรมการฝึก
  final trainingCollection = _firestore.collection('training_programs');
  await trainingCollection.doc('sit').set({
    'id': 'sit',
    'name': 'Sit Training',
    'description': 'Train your dog to sit on command.',
    'difficulty': 'Beginner',
    'duration': 15,
    'steps': [
      'Call your dog\'s name',
      'Show the sit gesture',
      'Reward with a treat'
    ],
  });
  await trainingCollection.doc('stay').set({
    'id': 'stay',
    'name': 'Stay Training',
    'description': 'Teach your dog to stay in place.',
    'difficulty': 'Intermediate',
    'duration': 20,
    'steps': [
      'Call your dog\'s name',
      'Give the stay command',
      'Reward if they stay'
    ],
  });

  print('Demo data added successfully!');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await addDemoData(); // เรียกฟังก์ชันเพิ่มข้อมูล
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Demo Data')),
        body: Center(child: Text('Data added to Firestore!')),
      ),
    );
  }
}
