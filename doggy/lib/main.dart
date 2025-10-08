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
const kBgColor = Color(0xFFF7EFE7);
const kSurfaceCream = Color(0xFFEFE2D3);
const kFieldCream = Color(0xFFEAD8C8);
const kCancelColor = Color(0xFF7C5959);
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
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
      backgroundColor: kBgColor,
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(),
              // โลโก้
              Image.asset(
                'assets/images/doggy_logo.png',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),

              // ปุ่มเริ่มต้นใช้งาน (Guest)
              ElevatedButton(
                onPressed: () => _enterAsGuest(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'เริ่มต้นใช้งาน !',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // ปุ่มเข้าสู่ระบบ
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: kSurfaceCream,
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // ปุ่มสมัครสมาชิก
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.register, // << แก้ไขตรงนี้
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF8B4513),
                  side: const BorderSide(color: Color(0xFF8B4513), width: 1.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                ),
                child: const Text(
                  'สมัครสมาชิก',
                  style: TextStyle(fontSize: 18),
                ),
              ),
              const Spacer(flex: 2),

              // คำบรรยายเล็กๆ
              Text(
                'Doggy Training App\nฝึกสุนัขของคุณได้ง่าย ๆ ผ่านคอร์สเรียน',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20), // เพิ่มระยะห่างด้านล่าง
            ],
          ),
        ),
      ),
    );
  }
}