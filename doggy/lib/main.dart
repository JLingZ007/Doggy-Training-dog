import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

import 'routes/app_navigator.dart';
import 'routes/app_routes.dart';
import 'firebase_options.dart';
import 'services/chat_provider.dart';
import 'providers/community_provider.dart';
import 'package:lottie/lottie.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const kBgColor = Color(0xFFF7EFE7); // warm cream background
const kSurfaceCream = Color(0xFFEFE2D3); // slightly darker surface
const kFieldCream = Color(0xFFEAD8C8); // input/field fill
const kCancelColor = Color(0xFF7C5959); // dusty rose accent
const kPrimaryBrown = Color(0xFFB08968); // warm mid-brown
const kDarkBrown = Color(0xFF6D4C41); // deep brown text
const kLightPaw = Color(0xFFE8D5C0); // very light paw tint

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
    );
    debugPrint('Firebase App Check Activated (Debug Mode)');
  } catch (e) {
    debugPrint('Error activating App Check: $e');
  }

  runApp(const MyApp());
}

// ─── App Root ─────────────────────────────────────────────────────────────────
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
        theme: _buildTheme(),
        home: const AuthGate(),
        onGenerateRoute: AppNavigator.onGenerateRoute,
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: false,
      scaffoldBackgroundColor: kBgColor,
      fontFamily: 'Nunito',
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryBrown,
        background: kBgColor,
        primary: kDarkBrown,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: kDarkBrown,
      ),
      cardColor: Colors.white,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kDarkBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kDarkBrown,
          side: const BorderSide(color: kDarkBrown, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ─── Auth Gate ────────────────────────────────────────────────────────────────
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
          return const _SplashScreen();
        }
        if (snap.hasData) {
          _safeNavigate(AppRoutes.home);
        } else {
          _safeNavigate(AppRoutes.mainPage);
        }
        return const _SplashScreen();
      },
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          _AnimatedBackground(),
          Center(
            child: CircularProgressIndicator(
              color: kPrimaryBrown,
              strokeWidth: 2.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Main Page ────────────────────────────────────────────────────────────────
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

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
        SnackBar(
          content: const Text('ไม่สามารถเข้าแบบ Guest ได้'),
          backgroundColor: kCancelColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: kBgColor,
      body: Stack(
        children: [
          // ── Animated paw background ──
          const _AnimatedBackground(),

          // ── Decorative top wave ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopWaveDecoration(screenWidth: size.width),
          ),

          // ── Main content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  children: [
                    // ── Hero section ──
                    Expanded(
                      flex: 5,
                      child: _HeroSection(screenHeight: size.height),
                    ),

                    // ── Bottom card with buttons ──
                    _BottomActionCard(onGuestTap: () => _enterAsGuest(context)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Section ─────────────────────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final double screenHeight;
  const _HeroSection({required this.screenHeight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // App badge / pill
          

          // Logo
          Hero(
            tag: 'app_logo',
            child: Image.asset(
              'assets/images/doggy_logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),

          // const SizedBox(height: 12),

          // App name
          // const Text(
          //   'Doggy Training',
          //   style: TextStyle(
          //     fontSize: 32,
          //     fontWeight: FontWeight.w800,
          //     color: kDarkBrown,
          //     letterSpacing: -0.5,
          //   ),
          // ),

          const SizedBox(height: 8),

          // Tagline
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: kPrimaryBrown,
              ),
              children: const [
  TextSpan(text: 'ฝึกสุนัขของคุณให้ดีขึ้น\nไปพร้อมกับ '),
  TextSpan(
    text: 'Doggy Training',
    style: TextStyle(
      fontWeight: FontWeight.w700,
      color: kCancelColor,
    ),
  ),
]
            ),
          ),

          const SizedBox(height: 28),

          // Dog illustration with shadow
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Ellipse shadow beneath dog
              Container(
                width: 160,
                height: 24,
                decoration: BoxDecoration(
                  color: kPrimaryBrown.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              // Dog image
              Hero(
                tag: 'dog_illustration',
                child: Lottie.asset(
                  'assets/lottie/dogwalk.json', // ← .json แทน .lottie
                  height: screenHeight * 0.2,
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
            ],
          ),

          // Feature chips
          // const SizedBox(height: 24),
          // _FeatureChipsRow(),
        ],
      ),
    );
  }
}

// ─── Feature Chips ────────────────────────────────────────────────────────────
// class _FeatureChipsRow extends StatelessWidget {
//   const _FeatureChipsRow();

//   static const _chips = [
//     (Icons.school_rounded, 'คำสั่งฝึก'),
//     (Icons.forum_rounded, 'ชุมชน'),
//     (Icons.star_rounded, 'ติดตาม'),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: _chips.map((chip) {
//         return Container(
//           margin: const EdgeInsets.symmetric(horizontal: 5),
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.65),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: kLightPaw, width: 1),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(chip.$1, size: 14, color: kCancelColor),
//               const SizedBox(width: 5),
//               Text(
//                 chip.$2,
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: kDarkBrown,
//                 ),
//               ),
//             ],
//           ),
//         );
//       }).toList(),
//     );
//   }
// }

// ─── Bottom Action Card ───────────────────────────────────────────────────────
class _BottomActionCard extends StatelessWidget {
  final VoidCallback onGuestTap;
  const _BottomActionCard({required this.onGuestTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: kLightPaw, width: 1),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBrown.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Primary CTA: Start with AI ──
          // SizedBox(
          //   width: double.infinity,
          //   child: ElevatedButton.icon(
          //     icon: const Icon(Icons.pets, size: 18),
          //     label: const Text('เริ่มต้นใช้งาน Doggy Training'),
          //     onPressed: onGuestTap,
          //     style: ElevatedButton.styleFrom(
          //       backgroundColor: kDarkBrown,
          //       foregroundColor: Colors.white,
          //       padding: const EdgeInsets.symmetric(vertical: 16),
          //       shape: RoundedRectangleBorder(
          //         borderRadius: BorderRadius.circular(16),
          //       ),
          //       textStyle: const TextStyle(
          //         fontSize: 16,
          //         fontWeight: FontWeight.w700,
          //       ),
          //     ),
          //   ),
          // ),

          const SizedBox(height: 12),

          // ── Secondary: Login ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
              style: OutlinedButton.styleFrom(
                foregroundColor: kDarkBrown,
                side: const BorderSide(color: kDarkBrown, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('เข้าสู่ระบบ'),
            ),
          ),

          const SizedBox(height: 16),

          // ── Divider ──
          Row(
            children: [
              Expanded(child: Divider(color: kLightPaw, thickness: 1)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'ยังไม่มีบัญชี?',
                  style: TextStyle(
                    fontSize: 13,
                    color: kPrimaryBrown.withOpacity(0.7),
                  ),
                ),
              ),
              Expanded(child: Divider(color: kLightPaw, thickness: 1)),
            ],
          ),

          const SizedBox(height: 12),

          // ── Register link ──
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.register),
            child: const Text(
              'สมัครสมาชิก →',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: kCancelColor,
                decoration: TextDecoration.underline,
                decorationColor: kCancelColor,
              ),
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─── Top Wave Decoration ──────────────────────────────────────────────────────
class _TopWaveDecoration extends StatelessWidget {
  final double screenWidth;
  const _TopWaveDecoration({required this.screenWidth});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(screenWidth, 120),
      painter: _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kSurfaceCream.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.9,
        size.width * 0.55,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.78,
        size.height * 0.45,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Animated Paw Background ──────────────────────────────────────────────────
class _Paw {
  final Animation<Offset> animation;
  final double size;
  final Color color;

  _Paw(this.animation, this.size, this.color);
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with TickerProviderStateMixin {
  List<_Paw> _paws = [];
  List<AnimationController> _controllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initPaws(12);
        setState(() {});
      }
    });
  }

  void _initPaws(int count) {
    final random = Random();
    final screenSize = MediaQuery.of(context).size;
    _controllers = [];
    _paws = [];

    for (int i = 0; i < count; i++) {
      final controller = AnimationController(
        duration: Duration(seconds: random.nextInt(6) + 4),
        vsync: this,
      )..repeat(reverse: true);
      _controllers.add(controller);

      final startOffset = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );
      final endOffset = Offset(
        random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height,
      );

      final animation = Tween<Offset>(begin: startOffset, end: endOffset)
          .animate(
              CurvedAnimation(parent: controller, curve: Curves.easeInOut));

      final size = random.nextDouble() * 50 + 20;
      final opacity = random.nextDouble() * 0.15 + 0.04;
      final color = kPrimaryBrown.withOpacity(opacity);

      _paws.add(_Paw(animation, size, color));
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_paws.isEmpty) return const SizedBox.expand();
    return AnimatedBuilder(
      animation: Listenable.merge(_controllers),
      builder: (_, __) => CustomPaint(
        painter: _PawPainter(_paws),
        size: Size.infinite,
      ),
    );
  }
}

class _PawPainter extends CustomPainter {
  final List<_Paw> paws;
  _PawPainter(this.paws);

  @override
  void paint(Canvas canvas, Size size) {
    for (final paw in paws) {
      final span = TextSpan(
        text: String.fromCharCode(Icons.pets.codePoint),
        style: TextStyle(
          fontSize: paw.size,
          fontFamily: Icons.pets.fontFamily,
          color: paw.color,
        ),
      );
      final tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(
        canvas,
        Offset(
          paw.animation.value.dx - tp.width / 2,
          paw.animation.value.dy - tp.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
