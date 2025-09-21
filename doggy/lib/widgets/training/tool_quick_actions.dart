import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';

class ToolQuickActions extends StatefulWidget {
  final bool showClicker;
  final bool showWhistle;

  /// ตั้งค่าเริ่มต้นความถี่ของนกหวีด (Hz) ถ้าไม่กำหนดจะใช้ 4000 Hz
  final double initialWhistleHz;

  const ToolQuickActions({
    super.key,
    this.showClicker = false,
    this.showWhistle = false,
    this.initialWhistleHz = 4000.0,
  });

  @override
  State<ToolQuickActions> createState() => _ToolQuickActionsState();
}

class _ToolQuickActionsState extends State<ToolQuickActions> {
  // --- Clicker ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playClickerSound() async {
    // ต้องมีไฟล์ assets/sounds/clicker_sound.mp3 ใน pubspec.yaml
    await _audioPlayer.play(AssetSource('sounds/clicker_sound.mp3'));
  }

  // --- Whistle ---
  final FlutterSoundPlayer _whistlePlayer = FlutterSoundPlayer();
  bool _whistleReady = false;
  bool _whistlePlaying = false;

  // ช่วงความถี่ที่แนะนำ (ปรับได้ตามต้องการ)
  static const double _minHz = 3000.0;
  static const double _maxHz = 12000.0;
  double _frequency = 4000.0; // default

  @override
  void initState() {
    super.initState();
    _frequency = widget.initialWhistleHz.clamp(_minHz, _maxHz);
    _initWhistle();
  }

  Future<void> _initWhistle() async {
    await _whistlePlayer.openPlayer();
    if (mounted) setState(() => _whistleReady = true);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _whistlePlayer.stopPlayer();
    _whistlePlayer.closePlayer();
    super.dispose();
  }

  Future<Uint8List> _generateSineWaveBuffer(
      double frequency, int durationMs) async {
    const int sampleRate = 44100;
    final int sampleCount = (sampleRate * durationMs / 1000).round();
    final Float64List samples = Float64List(sampleCount);

    // sine wave
    for (int i = 0; i < sampleCount; i++) {
      samples[i] = sin(2 * pi * frequency * i / sampleRate);
    }

    // 16-bit PCM LE
    final Uint8List pcm = Uint8List(sampleCount * 2);
    final byteData = ByteData.view(pcm.buffer);
    for (int i = 0; i < sampleCount; i++) {
      int val = (samples[i] * 32767).toInt();
      byteData.setInt16(i * 2, val, Endian.little);
    }
    return pcm;
  }

  Future<void> _startWhistle() async {
    if (!_whistleReady || _whistlePlaying) return;
    setState(() => _whistlePlaying = true);
    await _playWhistleChunkAndLoop();
  }

  Future<void> _playWhistleChunkAndLoop() async {
    if (!_whistlePlaying) return;

    // เล่นเป็นช่วงๆ แล้ววน (เช่น 1200ms) เพื่อให้เปลี่ยนความถี่ระหว่างเล่นได้
    final buffer = await _generateSineWaveBuffer(_frequency, 1200);
    await _whistlePlayer.startPlayer(
      fromDataBuffer: buffer,
      codec: Codec.pcm16,
      sampleRate: 44100,
      numChannels: 1,
      whenFinished: () async {
        if (_whistlePlaying) {
          await _playWhistleChunkAndLoop();
        }
      },
    );
  }

  Future<void> _stopWhistle() async {
    if (!_whistlePlaying) return;
    await _whistlePlayer.stopPlayer();
    setState(() => _whistlePlaying = false);
  }

  Future<void> _handleWhistleFreqChanged(double value) async {
    final v = value.clamp(_minHz, _maxHz);
    setState(() => _frequency = v);

    // ถ้ากำลังเล่นอยู่ ให้รีสตาร์ตชิ้นเสียงด้วยความถี่ใหม่เพื่อให้ได้ยินผลทันที
    if (_whistlePlaying) {
      await _whistlePlayer.stopPlayer();
      await _playWhistleChunkAndLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showClicker && !widget.showWhistle)
      return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (widget.showClicker)
              OutlinedButton.icon(
                onPressed: _playClickerSound,
                icon: const Icon(Icons.touch_app),
                label: const Text('คลิกเกอร์'),
              ),
            if (widget.showWhistle)
              OutlinedButton.icon(
                onPressed: !_whistleReady
                    ? null
                    : (_whistlePlaying ? _stopWhistle : _startWhistle),
                icon: const Icon(Icons.campaign_outlined),
                label: Text(_whistlePlaying ? 'หยุดนกหวีด' : 'นกหวีด'),
              ),
          ],
        ),

        // แสดงตัวเลื่อนความถี่เมื่อเปิดใช้ "นกหวีด"
        if (widget.showWhistle) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('ความถี่คลื่นเสียงนกหวีด'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${_frequency.toStringAsFixed(0)} Hz'),
              ),
            ],
          ),
          Slider(
            value: _frequency,
            min: _minHz,
            max: _maxHz,
            divisions: 90,
            label: '${_frequency.toStringAsFixed(0)} Hz',
            onChanged:
                !_whistleReady ? null : (v) => _handleWhistleFreqChanged(v),
          ),
        ],
      ],
    );
  }
}
