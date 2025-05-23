import 'package:flutter/material.dart';
import 'routes/app_navigator.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'views/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // เริ่มต้น Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
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
          '',
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
                Navigator.pushNamed(context, AppRoutes.home); // ใช้ AppRoutes.home
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 1),
                minimumSize: const Size(250, 50), // กำหนดความกว้างและความสูงขั้นต่ำ
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
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
            const SizedBox(height: 15), // ระยะห่างระหว่างปุ่ม

            // ปุ่ม "เข้าสู่ระบบ" (เหมือนปุ่ม "เริ่มต้นใช้งาน")
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login); // ใช้ AppRoutes.login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                side: const BorderSide(color: Colors.black, width: 1),
                minimumSize: const Size(250, 50), // กำหนดความกว้างและความสูงขั้นต่ำ
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: const Text(
                'เข้าสู่ระบบ',
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
