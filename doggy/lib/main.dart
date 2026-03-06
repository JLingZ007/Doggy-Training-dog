import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// 1. เพิ่ม Import ของ App Check
import 'package:firebase_app_check/firebase_app_check.dart'; 

import 'routes/app_navigator.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';

import 'services/chat_provider.dart';
import 'providers/community_provider.dart';

/// === Palette ให้เหมือนหน้า Login/Register ===
const kBgColor = Color(0xFFF7EFE7);
const kSurfaceCream = Color(0xFFEFE2D3);
const kFieldCream = Color(0xFFEAD8C8);
const kCancelColor = Color(0xFF7C5959);
const kBorder = Colors.black87;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ==========================================================
  // ** เพิ่ม: โหลดไฟล์ .env ก่อนการใช้งาน Firebase **
  // ==========================================================
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ==========================================================
  // 2. ** เพิ่ม: เปิดใช้งาน Firebase App Check **
  // ==========================================================
  try {
    await FirebaseAppCheck.instance.activate(
      // ใช้ .debug สำหรับการทดสอบใน Emulator/อุปกรณ์จริง
      // เมื่อจะปล่อยแอปจริง ค่อยเปลี่ยนเป็น .playIntegrity
      androidProvider: AndroidProvider.debug, 
      
      // สำหรับ iOS (ถ้ามี)
      // appleProvider: AppleProvider.debug,
    );
    print('Firebase App Check Activated (Debug Mode)');
  } catch (e) {
    print('Error activating App Check: $e');
  }
  // ==========================================================

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
        home: const AuthGate(),
        onGenerateRoute: AppNavigator.onGenerateRoute,
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  void _safeNavigate(String route) {
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
          _safeNavigate(AppRoutes.home);
        } else {
          _safeNavigate(AppRoutes.mainPage);
        }
        return const _Splash();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    // ** เปลี่ยนเป็น Stack เพื่อวางอนิเมชันพื้นหลัง **
    return const Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // Widget อนิเมชันพื้นหลัง
          _AnimatedBackground(),
          // ตัวโหลดข้อมูล
          Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<void> _enterAsGuest(BuildContext context) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      // ignore: use_build_context_synchronously
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่สามารถเข้าแบบ Guest ได้')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // ** เปลี่ยน body เป็น Stack เพื่อเพิ่มอนิเมชัน **
        body: Stack(
      children: [
        // Widget อนิเมชันพื้นหลัง
        const _AnimatedBackground(),
        // UI เดิมของหน้า
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // โลโก้
                  Image.asset(
                    'assets/images/doggy_logo.png',
                    width: 250,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 50),

                  // ปุ่มเริ่มต้นใช้งาน (Guest)
                  ElevatedButton(
                    onPressed: () => _enterAsGuest(context),
                    child: const Text('เริ่มต้นใช้งาน !'),
                  ),
                  const SizedBox(height: 16),

                  // ปุ่มเข้าสู่ระบบ
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                  const SizedBox(height: 24),

                  // ปุ่มสมัครสมาชิก (TextButton)
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.register),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.brown.shade700,
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    child: const Text('สมัครสมาชิกที่นี่'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ));
  }
}



/// Model สำหรับเก็บข้อมูลของไอคอนอุ้งเท้าแต่ละอัน
class _Paw {
  final Animation<Offset> animation;
  final double size;
  final Color color;
  final IconData icon;

  _Paw(this.animation, this.size, this.color, this.icon);
}

/// Widget หลักที่จัดการสถานะและสร้างอนิเมชัน
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  late List<_Paw> _paws;
  late List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = [];
    _paws = [];
    // เราจะเริ่มสร้างไอคอนหลังจากที่ widget ถูกสร้างขึ้นแล้ว
    // เพื่อให้เราสามารถเข้าถึงขนาดของหน้าจอได้
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initPaws(15); // จำนวนไอคอนที่ต้องการ
        setState(() {});
      }
    });
  }

  void _initPaws(int count) {
    final random = Random();
    final screenSize = MediaQuery.of(context).size;

    for (int i = 0; i < count; i++) {
      // สร้าง AnimationController สำหรับแต่ละไอคอน
      final controller = AnimationController(
        duration: Duration(seconds: random.nextInt(5) + 3), // สุ่มความเร็ว (3-8 วินาที)
        vsync: this,
      )..repeat(reverse: true); // ให้เล่นวนไปกลับ
      _controllers.add(controller);

      // สุ่มตำแหน่งเริ่มต้นและสิ้นสุด
      final startOffset = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
      final endOffset = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );

      // สร้าง Animation ที่เปลี่ยนค่าตำแหน่ง (Offset)
      final animation = Tween<Offset>(
        begin: startOffset,
        end: endOffset,
      ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      // สุ่มขนาดและสี
      final size = random.nextDouble() * 60 + 30; // ปรับขนาดไอคอน
      final color = kFieldCream.withOpacity(random.nextDouble() * 0.4 + 0.1);

      _paws.add(_Paw(animation, size, color, Icons.pets));
    }
  }

  @override
  void dispose() {
    // ต้อง dispose controller ทั้งหมดเพื่อป้องกัน memory leak
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ถ้ายังไม่มีไอคอน ให้แสดง Container ว่างๆ ไปก่อน
    if (_paws.isEmpty) {
      return Container();
    }
    // ใช้ CustomPaint เพื่อวาดไอคอนตามอนิเมชัน
    return CustomPaint(
      painter: _PawPainter(_paws),
      child: Container(),
    );
  }
}

/// Class ที่ทำหน้าที่วาดไอคอนอุ้งเท้าลงบน Canvas
class _PawPainter extends CustomPainter {
  final List<_Paw> paws;

  _PawPainter(this.paws);

  @override
  void paint(Canvas canvas, Size size) {
    for (final paw in paws) {
      final textSpan = TextSpan(
        text: String.fromCharCode(paw.icon.codePoint),
        style: TextStyle(
          fontSize: paw.size,
          fontFamily: paw.icon.fontFamily,
          color: paw.color,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      // จัดตำแหน่งให้ไอคอนอยู่ตรงกลางของจุด offset
      final offset = Offset(
        paw.animation.value.dx - textPainter.width / 2,
        paw.animation.value.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}