// main.dart
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
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

        // ❗ ให้ AuthGate เป็นตัวตัดสินใจหน้าเริ่มต้น (จำสถานะล็อกอินเดิม)
        home: const AuthGate(),

        onGenerateRoute: AppNavigator.onGenerateRoute,
      ),
    );
  }
}

/// ฟังสถานะ user จาก Firebase แล้วนำทางอัตโนมัติ
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  void _safeNavigate(String route) {
    // กัน multiple push เวลา stream มีการ emit ใกล้ๆกัน
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const _Splash();
        }

        if (snap.hasData) {
          // มีผู้ใช้เดิม (อีเมล/กูเกิล/นิรนามก็ได้) → เข้าแอป
          _safeNavigate(AppRoutes.home);
        } else {
          // ไม่มีผู้ใช้ → ไปหน้า Landing ของคุณ
          _safeNavigate(AppRoutes.mainPage);
        }

        // ระหว่างกำลังนำทาง แสดง splash ว่างๆ
        return const _Splash();
      },
    );
  }
}

/// Splash/Loading หน้าจอเรียบๆระหว่างตัดสินใจเส้นทาง
class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: kBgColor,
    );
  }
}

/// Landing Page เดิมของคุณ (ปรับปุ่ม "เริ่มต้นใช้งาน !" ให้ล็อกอินนิรนามเฉพาะตอนกด)
class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<void> _enterAsGuest(BuildContext context) async {
    try {
      // ล็อกอินนิรนามเฉพาะเมื่อยังไม่มี user
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      // แล้วเข้า Home
      // ใช้ removeUntil กันย้อนกลับไปหน้า main
      // ถ้าใช้ onGenerateRoute แล้วมี guard ใน home อยู่ก็โอเค
      // แต่ตรงนี้เข้าได้เลยตามที่คุณออกแบบ
      // (ใช้ชื่อ route ของคุณเอง)
      // ignore: use_build_context_synchronously
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      // แจ้งผู้ใช้กรณีเข้าโหมด Guest ไม่สำเร็จ
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเข้าแบบ Guest ได้')),
      );
    }
  }

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

            // ปุ่ม "เริ่มต้นใช้งาน !" → เข้าแบบ Guest
            ElevatedButton(
              onPressed: () => _enterAsGuest(context),
              child: const Text(
                'เริ่มต้นใช้งาน !',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15),

            // ปุ่ม "เข้าสู่ระบบ" → ไปหน้า Login
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
