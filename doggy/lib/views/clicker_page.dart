import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/bottom_navbar.dart';

class ClickerPage extends StatefulWidget {
  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _selectedIndex = 0;

  Future<void> _playClickerSound() async {
    await _audioPlayer.play(AssetSource('sounds/clicker_sound.mp3'));
  }

  void _onNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8), // สีพื้นหลังเทาอ่อน
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        title: const Text('คลิกเกอร์', style: TextStyle(color: Colors.black)),
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
              onTap: _playClickerSound,
              child: Image.asset(
                'assets/images/clicker.png',
                width: 200,
                height: 200,
              ),
            ),
            const SizedBox(height: 100),
            const Text(
              "กดที่หน้าจอเพื่อส่งเสียง",
              style: TextStyle(
                fontSize: 18,
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
                
              ),
            ),
          ],
        ),
      ),
    );
  }
}
