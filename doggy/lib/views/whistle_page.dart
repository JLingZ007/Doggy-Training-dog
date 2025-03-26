import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class WhistlePage extends StatelessWidget {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playWhistleSound() async {
    await _audioPlayer.play(AssetSource('sounds/whistle_sound.mp3'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text('นกหวีด', style: TextStyle(color: Colors.black)),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onTap: _playWhistleSound,
          child: CircleAvatar(
            radius: 80,
            backgroundColor: Colors.grey[400],
            child: Icon(Icons.volume_up, size: 60, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}
