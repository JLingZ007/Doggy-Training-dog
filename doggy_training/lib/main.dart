import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// กำหนดค่าที่คัดลอกจาก Firebase Console มาใช้
const FirebaseOptions firebaseOptions = FirebaseOptions(
  apiKey: "AIzaSyDHf1jHC55OuS8qHNvq8MggPc14tLXp8Fs",
  appId: "1:1050097974113:web:ec6f97b79374b7dfd5a320",
  messagingSenderId: "1050097974113",
  projectId: "doggy-training-61db7",
  authDomain: "doggy-training-61db7.firebaseapp.com",
  storageBucket: "doggy-training-61db7.firebasestorage.app",
  measurementId: "G-WK106JB2ZG",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // เรียกใช้งาน Firebase ด้วยการตั้งค่า FirebaseOptions
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Test',
      home: FirebaseTestPage(),
    );
  }
}

class FirebaseTestPage extends StatefulWidget {
  @override
  _FirebaseTestPageState createState() => _FirebaseTestPageState();
}

class _FirebaseTestPageState extends State<FirebaseTestPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _message = '';

  @override
  void initState() {
    super.initState();
    _addUser();
  }

  // ฟังก์ชันเพิ่มข้อมูลไปยัง Firestore
  Future<void> _addUser() async {
    try {
      // เพิ่มข้อมูลใหม่ในคอลเล็กชัน 'users'
      await _firestore.collection('users').add({
        'name': 'John Doe',
        'email': 'johndoe@example.com',
      });

      // เมื่อเพิ่มสำเร็จให้ดึงข้อมูลมาแสดง
      _fetchUsers();
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  // ฟังก์ชันดึงข้อมูลจาก Firestore
  Future<void> _fetchUsers() async {
    try {
      // ดึงข้อมูลจากคอลเล็กชัน 'users'
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      if (snapshot.docs.isNotEmpty) {
        setState(() {
          _message = 'User: ${snapshot.docs[0]['name']}';
        });
      } else {
        setState(() {
          _message = 'No users found.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Test')),
      body: Center(
        child: Text(_message.isEmpty ? 'Loading...' : _message),
      ),
    );
  }
}
