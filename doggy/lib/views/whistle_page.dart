import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/bottom_navbar.dart';

class WhistlePage extends StatefulWidget {
  @override
  State<WhistlePage> createState() => _WhistlePageState();
}

class _WhistlePageState extends State<WhistlePage> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;
  double _frequency = 1000.0;
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
    _player.stopPlayer();
    _player.closePlayer();
    super.dispose();
  }

  Future<Uint8List> _generateSineWaveBuffer(double frequency, int durationMs) async {
    const int sampleRate = 44100;
    final int sampleCount = (sampleRate * durationMs / 1000).round();
    final Float64List samples = Float64List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      samples[i] = sin(2 * pi * frequency * i / sampleRate);
    }

    final Uint8List pcm = Uint8List(sampleCount * 2);
    final ByteData byteData = ByteData.view(pcm.buffer);

    for (int i = 0; i < sampleCount; i++) {
      int val = (samples[i] * 32767).toInt();
      byteData.setInt16(i * 2, val, Endian.little);
    }

    return pcm;
  }

  Future<void> _startSineWave() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);
    final buffer = await _generateSineWaveBuffer(_frequency, 10000); // 2 วินาทีวนลูป
    await _player.startPlayer(
      fromDataBuffer: buffer,
      codec: Codec.pcm16,
      sampleRate: 44100,
      numChannels: 1,
      whenFinished: () {
        if (_isPlaying) _startSineWave(); // loop play
      },
    );
  }

  Future<void> _stopSineWave() async {
    if (!_isPlaying) return;

    await _player.stopPlayer();
    setState(() => _isPlaying = false);
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
            GestureDetector(
              onTapDown: (_) => _startSineWave(),
              onTapUp: (_) => _stopSineWave(),
              onTapCancel: () => _stopSineWave(),
              child: Column(
                children: [
                  Image.asset('assets/images/whistle.png', height: 150),
                  const SizedBox(height: 12),
                  Text(
                    _isPlaying ? "Playing..." : "Hold to Play",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Slider(
              value: _frequency,
              min: 100,
              max: 20000,
              divisions: 500,
              label: '${_frequency.toStringAsFixed(0)} Hz',
              activeColor: Colors.teal,
              onChanged: (value) {
                setState(() => _frequency = value);
              },
            ),
            Text(
              "${_frequency.toStringAsFixed(0)} Hz",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
