import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'views/training_type.dart';
import 'firebase_options.dart'; // นำเข้าไฟล์ firebase_options.dart ที่ FlutterFire CLI สร้าง

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // ใช้ตัวเลือก Firebase ที่ถูกต้องสำหรับแพลตฟอร์ม
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doggy Training',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.brown,
      ),
      home: const TrainingTypePage(),
    );
  }
}
