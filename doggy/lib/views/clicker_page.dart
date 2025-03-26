import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class ClickerPage extends StatelessWidget {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playClickerSound() async {
    await _audioPlayer.play(AssetSource('sounds/clicker_sound.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        title: const Text('คลิกเกอร์', style: TextStyle(color: Colors.black)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: _playClickerSound,
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.black54,
            child: Icon(Icons.pets, size: 60, color: Colors.amber),
          ),
        ),
      ),
    );
  }
}
