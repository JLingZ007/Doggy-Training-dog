import 'package:flutter/material.dart';
import 'routes/app_navigator.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

  const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBahPCzPOwsxEEinx8n6gAOHAPABQfAS7s",
    authDomain: "doggy-training-51e3d.firebaseapp.com",
    projectId: "doggy-training-51e3d",
    storageBucket: "doggy-training-51e3d.firebasestorage.app",
    messagingSenderId: "451937564533",
    appId: "1:451937564533:web:ea4f784b31d479a737c53c",
    measurementId: "G-7LPLJXHWNF"
  );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase ด้วย FirebaseOptions
  await Firebase.initializeApp(
    options: web,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Doggy Training',
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.mainPage, // เส้นทางเริ่มต้น
      onGenerateRoute: AppNavigator.onGenerateRoute, // ใช้ Navigator ที่สร้างไว้
    );
  }
}

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'First Page',
          style: TextStyle(color: Colors.grey),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0, // ทำให้ AppBar โปร่งใส
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // รูปภาพ
            Image.asset(
              'assets/images/doggy_logo.png', // ใส่ path ของไฟล์รูปภาพใน assets
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),

            // ปุ่ม "เริ่มต้นใช้งาน"
            ElevatedButton(
              onPressed: () {
                // นำทางไปยังหน้า HomePage
                Navigator.pushNamed(context, '/home');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 1),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'เริ่มต้นใช้งาน !',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
