import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:audioplayers/audioplayers.dart';

class ToolQuickActions extends StatefulWidget {
  final bool showClicker;
  final bool showWhistle;


  final double initialWhistleHz;

  const ToolQuickActions({
    super.key,
    this.showClicker = false,
    this.showWhistle = false,
    this.initialWhistleHz = 18000.0, 
  });

  @override
  State<ToolQuickActions> createState() => _ToolQuickActionsState();
}

class _ToolQuickActionsState extends State<ToolQuickActions> {
  // --- Clicker ---
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playClickerSound() async {
    await _audioPlayer.play(AssetSource('sounds/clicker_sound.wav'));
  }

  // --- Whistle ---
  final FlutterSoundPlayer _whistlePlayer = FlutterSoundPlayer();
  bool _whistleReady = false;
  bool _whistlePlaying = false;

  // 1. ปรับช่วงความถี่ให้เหมาะกับการฝึกสุนัข (inaudible to most humans)
  static const double _minHz = 15000.0;
  static const double _maxHz = 22000.0;
  double _frequency = 18000.0; // default initial value

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

    for (int i = 0; i < sampleCount; i++) {
      samples[i] = sin(2 * pi * frequency * i / sampleRate);
    }

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

    if (_whistlePlaying) {
      await _whistlePlayer.stopPlayer();
      await _playWhistleChunkAndLoop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showClicker && !widget.showWhistle) {
      return const SizedBox.shrink();
    }
      
    // 3. เตรียมข้อความแสดงผลเป็น kHz
    final String frequencyLabel = '${(_frequency / 1000).toStringAsFixed(1)} kHz';

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

        if (widget.showWhistle) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('ความถี่คลื่นเสียง'),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(6),
                ),
                // แสดงผลเป็น kHz
                child: Text(frequencyLabel),
              ),
            ],
          ),
          Slider(
            value: _frequency,
            min: _minHz,
            max: _maxHz,
            // 4. ปรับ divisions ให้สอดคล้องกับช่วงใหม่ (7000 Hz / step 100 Hz = 70)
            divisions: 70,
            label: frequencyLabel,
            onChanged:
                !_whistleReady ? null : (v) => _handleWhistleFreqChanged(v),
          ),
        ],
      ],
    );
  }
}