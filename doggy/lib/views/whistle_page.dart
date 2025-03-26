import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/bottom_navbar.dart';

class WhistlePage extends StatefulWidget {
  @override
  State<WhistlePage> createState() => _WhistlePageState();
}

class _WhistlePageState extends State<WhistlePage> {

  final AudioPlayer _audioPlayer = AudioPlayer();

  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  double _frequency = 1000.0; // แนะนำเริ่มต้นที่ 1000 Hz
  int _selectedIndex = 0;

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _player.openPlayer();
  }

  @override
  void dispose() {
    _player.closePlayer();
    super.dispose();
  }

  Future<void> _playClickerSound() async {
    await _audioPlayer.play(AssetSource('sounds/whistle.mp3'));
  }

  // Future<void> testTone() async {
  //   const int sampleRate = 44100;
  //   const int durationMs = 1000;
  //   const double freq = 1000.0;

  //   final int sampleCount = (sampleRate * (durationMs / 1000)).round();
  //   final Float64List samples = Float64List(sampleCount);

  //   for (int i = 0; i < sampleCount; i++) {
  //     samples[i] = sin(2 * pi * freq * i / sampleRate);
  //   }

  //   final Uint8List pcm = Uint8List(sampleCount * 2);
  //   final ByteData bd = ByteData.view(pcm.buffer);
  //   for (int i = 0; i < sampleCount; i++) {
  //     int val = (samples[i] * 32767).toInt();
  //     bd.setInt16(i * 2, val, Endian.little);
  //   }

  //   final player = FlutterSoundPlayer();
  //   await player.openPlayer();
  //   await player.startPlayer(
  //     fromDataBuffer: pcm,
  //     codec: Codec.pcm16,
  //     sampleRate: sampleRate,
  //     numChannels: 1,
  //     whenFinished: () async => await player.stopPlayer(),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        title: const Text('นกหวีด', style: TextStyle(color: Colors.black)),
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
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Whistle Button
            GestureDetector(
              // onTap: testTone,
              onTap:  _playClickerSound,
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/whistle.png',
                    height: 150,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isPlaying ? "Playing..." : "Press Whistle for Sound",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Slider ปรับความถี่เสียง
            Slider(
              value: _frequency,
              min: 100, // ✅ ปรับเริ่มต้นที่ 100 Hz
              max: 20000, // ✅ ปรับสูงสุดที่ 20,000 Hz
              divisions: 500, // ✅ ให้ละเอียดขึ้น (จะได้ขยับได้ smooth)
              label: '${_frequency.toStringAsFixed(2)} Hz',
              activeColor: Colors.teal,
              onChanged: (value) => setState(() => _frequency = value),
            ),
            Text(
              "${_frequency.toStringAsFixed(2)} Hz",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
