import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_navbar.dart';

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key});

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 0;

  bool _isPressed = false;

  Future<void> _playClickerSound() async {
  await _audioPlayer.stop(); // กันเสียงซ้อน
  await _audioPlayer.play(
    AssetSource('sounds/clicker_sound.wav'),
    volume: 1.0,
  );
}

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPressStart() {
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
    _playClickerSound();
  }

  void _onPressEnd() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text(
          'Clicker Training',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: (_) => _onPressStart(),
              onTapUp: (_) => _onPressEnd(),
              onTapCancel: _onPressEnd,
              child: AnimatedScale(
                scale: _isPressed ? 0.95 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    // boxShadow: [
                    //   BoxShadow(
                    //     color: Colors.black.withOpacity(
                    //       _isPressed ? 0.15 : 0.25,
                    //     ),
                    //     blurRadius: _isPressed ? 8 : 16,
                    //     offset: const Offset(0, 6),
                    //   ),
                    // ],
                  ),
                  child: Image.asset(
                    _isPressed
                        ? 'assets/images/clicker_use.png'
                        : 'assets/images/clicker_original.png',
                    width: 480,
                    height: 480,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isPressed ? 'กำลังส่งเสียงคลิก' : 'แตะเพื่อส่งเสียงคลิก',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.indigo,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ใช้สำหรับเสริมแรงเชิงบวกในการฝึกสุนัข',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
