import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/bottom_navbar.dart'; // ตรวจสอบว่า path ถูกต้อง

class WhistlePage extends StatefulWidget {
  @override
  State<WhistlePage> createState() => _WhistlePageState();
}

class _WhistlePageState extends State<WhistlePage> {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  bool _isPlaying = false;

  // 1. ปรับความถี่เริ่มต้นให้อยู่ในย่านความถี่สูง
  double _frequency = 18000.0; 
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

  // สร้าง Buffer เสียงคลื่น Sine
  Future<Uint8List> _generateSineWaveBuffer(double frequency, int durationMs) async {
    const int sampleRate = 44100;
    final int sampleCount = (sampleRate * durationMs / 1000).round();
    final Float64List samples = Float64List(sampleCount);

    for (int i = 0; i < sampleCount; i++) {
      // สูตรสร้างคลื่น Sine
      samples[i] = sin(2 * pi * frequency * i / sampleRate);
    }

    // แปลงข้อมูลเป็น PCM 16-bit
    final Uint8List pcm = Uint8List(sampleCount * 2);
    final ByteData byteData = ByteData.view(pcm.buffer);

    for (int i = 0; i < sampleCount; i++) {
      final int val = (samples[i] * 32767).toInt();
      byteData.setInt16(i * 2, val, Endian.little);
    }

    return pcm;
  }

  // เริ่มเล่นเสียง
  Future<void> _startSineWave() async {
    if (_isPlaying) return;

    setState(() => _isPlaying = true);

    // 5. ลดระยะเวลา Buffer เพื่อให้วนลูปได้เร็วขึ้น
    final buffer = await _generateSineWaveBuffer(_frequency, 2000); // 2 วินาที

    await _player.startPlayer(
      fromDataBuffer: buffer,
      codec: Codec.pcm16,
      sampleRate: 44100,
      numChannels: 1,
      whenFinished: () {
        // วนลูปเล่นเสียงถ้ายังกดค้างอยู่
        if (mounted && _isPlaying) {
          _startSineWave(); 
        }
      },
    );
  }

  // หยุดเล่นเสียง
  Future<void> _stopSineWave() async {
    if (!_isPlaying) return;
    
    await _player.stopPlayer();
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }
  
  // จัดการการเปลี่ยนแปลงความถี่
  void _onFrequencyChanged(double value) {
    setState(() {
      _frequency = value;
    });
    
    // 4. ถ้าเสียงกำลังเล่นอยู่ ให้หยุดและเริ่มใหม่ด้วยความถี่ใหม่ทันที
    if (_isPlaying) {
      _player.stopPlayer().then((_) {
        if (_isPlaying) { // ตรวจสอบอีกครั้งเผื่อผู้ใช้ปล่อยนิ้วพอดี
          _startSineWave();
        }
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    // 3. แปลงความถี่เป็น kHz เพื่อการแสดงผล
    String frequencyLabel = (_frequency / 1000).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        title: const Text('นกหวีดฝึกสุนัข', style: TextStyle(color: Colors.black)),
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
                    _isPlaying ? "กำลังเล่น..." : "กดค้างเพื่อเป่านกหวีด",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 2. ปรับ Slider ให้อยู่ในช่วงความถี่ที่เหมาะสม
            Slider(
              value: _frequency,
              min: 15000,
              max: 22000,
              divisions: 70, // (22000-15000)/100 = 70 steps
              label: '$frequencyLabel kHz',
              activeColor: const Color(0xFF8B4513), // สีน้ำตาลให้เข้ากับธีม
              onChanged: _onFrequencyChanged,
            ),
            Text(
              "$frequencyLabel kHz",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "ปรับหาความถี่ที่สุนัขของคุณตอบสนองได้ดีที่สุด",
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}