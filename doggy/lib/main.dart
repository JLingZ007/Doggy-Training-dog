import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'routes/app_navigator.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/chat_provider.dart';
import 'providers/community_provider.dart';

/// === Palette ให้เหมือนหน้า Login/Register ===
const kBgColor = Color(0xFFF7EFE7);     // พื้นหลังครีมอ่อน
const kSurfaceCream = Color(0xFFEFE2D3); // สีปุ่ม/การ์ดอ่อน
const kFieldCream = Color(0xFFEAD8C8);   // สีฟิลด์ (เผื่อใช้ในหน้าฟอร์มอื่น)
const kCancelColor = Color(0xFF7C5959);  // โทนม่วงน้ำตาล (ปุ่มยกเลิก)
const kBorder = Colors.black87;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously สำหรับการใช้งาน Firebase
  try {
    await FirebaseAuth.instance.signInAnonymously();
    // print('Signed in anonymously to Firebase');
  } catch (e) {
    // print('Error signing in anonymously: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: MaterialApp(
        title: 'Doggy Training',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: false,
          scaffoldBackgroundColor: kBgColor,
          fontFamily: 'Roboto',

          // โทนสีหลักให้ใกล้กับหน้า Login/Register
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFB08968),
            background: kBgColor,
            primary: Colors.brown,
          ),

          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.brown,
          ),

          cardColor: Colors.white,

          // ปุ่มหลักสไตล์เดียวกับหน้า Login/Register
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kSurfaceCream,
              foregroundColor: Colors.black87,
              elevation: 3,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: const BorderSide(color: kBorder, width: 1),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          // ปุ่มขอบ (ใช้กับปุ่มยกเลิกได้ ถ้าต้องการ)
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              backgroundColor: kCancelColor,
              foregroundColor: Colors.white,
              side: const BorderSide(color: kBorder, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        initialRoute: AppRoutes.mainPage,
        onGenerateRoute: AppNavigator.onGenerateRoute,
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // สีพื้นหลังจะมาจาก Theme (kBgColor)
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(''),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // โลโก้
            Image.asset(
              'assets/images/doggy_logo.png',
              width: 300,
              height: 300,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 20),

            // ปุ่ม "เริ่มต้นใช้งาน" (สไตล์เดียวกับหน้า Login/Register จาก Theme)
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.home);
              },
              child: const Text(
                'เริ่มต้นใช้งาน !',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),

            // ปุ่ม "เข้าสู่ระบบ"
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              child: const Text(
                'เข้าสู่ระบบ',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
