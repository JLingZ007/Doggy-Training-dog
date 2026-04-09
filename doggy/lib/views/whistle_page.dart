import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/bottom_navbar.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBg           = Color(0xFFF7EFE7);
const _kSurface      = Color(0xFFEFE2D3);
const _kFieldCream   = Color(0xFFEAD8C8);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);

class WhistlePage extends StatefulWidget {
  const WhistlePage({super.key});

  @override
  State<WhistlePage> createState() => _WhistlePageState();
}

class _WhistlePageState extends State<WhistlePage>
    with SingleTickerProviderStateMixin {
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool   _isPlaying   = false;
  double _frequency   = 18000.0;

  // ── Animation controller สำหรับ pulsing indicator ────────────────────────
  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  // ── Preset frequencies ────────────────────────────────────────────────────
  static const _presets = [
    _Preset('ฝึก', 17500,  Icons.school_rounded),
    _Preset('เรียก', 19000, Icons.record_voice_over_rounded),
    _Preset('หยุด',  21000, Icons.pan_tool_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _player.openPlayer();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _player.stopPlayer();
    _player.closePlayer();
    super.dispose();
  }

  // ── Generate realistic whistle sound ──────────────────────────────────────
  // เพิ่ม harmonics + envelope เพื่อให้ฟังดูเหมือนนกหวีดจริงมากขึ้น
  Future<Uint8List> _generateWhistleBuffer(
      double frequency, int durationMs) async {
    const int sampleRate = 44100;
    final int sampleCount = (sampleRate * durationMs / 1000).round();
    final ByteData byteData = ByteData(sampleCount * 2);

    // Attack/Release envelope (ms)
    const int attackMs  = 30;
    const int releaseMs = 50;
    final int attackSamples  = (sampleRate * attackMs  / 1000).round();
    final int releaseSamples = (sampleRate * releaseMs / 1000).round();

    for (int i = 0; i < sampleCount; i++) {
      // ── Envelope ─────────────────────────────────────────────────────────
      double env = 1.0;
      if (i < attackSamples) {
        env = i / attackSamples; // fade in
      } else if (i > sampleCount - releaseSamples) {
        env = (sampleCount - i) / releaseSamples; // fade out
      }

      // ── Fundamental + harmonics (เลียนแบบ overtone นกหวีด) ──────────────
      final double t = i / sampleRate;
      double sample = 0.0;
      sample += 0.70 * sin(2 * pi * frequency         * t); // fundamental
      sample += 0.18 * sin(2 * pi * frequency * 2     * t); // 2nd harmonic
      sample += 0.08 * sin(2 * pi * frequency * 3     * t); // 3rd harmonic
      sample += 0.04 * sin(2 * pi * (frequency + 150) * t); // slight detune

      // ── Apply envelope + soft clip ────────────────────────────────────────
      sample *= env;
      sample  = sample.clamp(-1.0, 1.0);

      final int val = (sample * 28000).toInt(); // ใช้ 28000 แทน 32767 เพื่อ headroom
      byteData.setInt16(i * 2, val, Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  // ── Start playing ─────────────────────────────────────────────────────────
  Future<void> _startWhistle() async {
    if (_isPlaying) return;
    HapticFeedback.mediumImpact();
    setState(() => _isPlaying = true);
    _pulseCtrl.repeat(reverse: true);

    await _playOnce();
  }

  Future<void> _playOnce() async {
    if (!_isPlaying || !mounted) return;
    final buffer = await _generateWhistleBuffer(_frequency, 1500);
    await _player.startPlayer(
      fromDataBuffer: buffer,
      codec: Codec.pcm16,
      sampleRate: 44100,
      numChannels: 1,
      whenFinished: () {
        if (mounted && _isPlaying) _playOnce();
      },
    );
  }

  // ── Stop playing ──────────────────────────────────────────────────────────
  Future<void> _stopWhistle() async {
    if (!_isPlaying) return;
    await _player.stopPlayer();
    if (mounted) {
      setState(() => _isPlaying = false);
      _pulseCtrl.stop();
      _pulseCtrl.reset();
    }
  }

  // ── Frequency changed ─────────────────────────────────────────────────────
  void _onFreqChanged(double v) {
    setState(() => _frequency = v);
    if (_isPlaying) {
      _player.stopPlayer().then((_) {
        if (mounted && _isPlaying) _playOnce();
      });
    }
  }

  // ── Apply preset ──────────────────────────────────────────────────────────
  void _applyPreset(_Preset p) {
    HapticFeedback.selectionClick();
    setState(() => _frequency = p.freq.toDouble());
    if (_isPlaying) {
      _player.stopPlayer().then((_) {
        if (mounted && _isPlaying) _playOnce();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final freqLabel =
        '${(_frequency / 1000).toStringAsFixed(1)} kHz';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leadingWidth: 56,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: _kSurface, shape: BoxShape.circle,
                border: Border.all(color: _kLightPaw),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: _kDarkBrown),
            ),
          ),
        ),
        title: const Text('นกหวีดฝึกสุนัข',
            style: TextStyle(
                color: _kDarkBrown,
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2)),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [

              // ── Whistle button ─────────────────────────────────────────
              _WhistleButton(
                isPlaying: _isPlaying,
                pulseAnim: _pulseAnim,
                onStart: _startWhistle,
                onStop: _stopWhistle,
              ),

              const SizedBox(height: 32),

              // ── Frequency card ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLightPaw),
                  boxShadow: [
                    BoxShadow(
                      color: _kPrimaryBrown.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Label row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.graphic_eq_rounded,
                              size: 16, color: _kPrimaryBrown),
                        ),
                        const SizedBox(width: 10),
                        const Text('ความถี่เสียง',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kDarkBrown)),
                        const Spacer(),
                        // Frequency badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _kDarkBrown,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(freqLabel,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Slider
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: _kDarkBrown,
                        inactiveTrackColor: _kFieldCream,
                        thumbColor: _kDarkBrown,
                        overlayColor: _kPrimaryBrown.withOpacity(0.12),
                        trackHeight: 5,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        value: _frequency,
                        min: 15000,
                        max: 22000,
                        divisions: 140,
                        onChanged: _onFreqChanged,
                      ),
                    ),

                    // Range labels
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('15.0 kHz',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _kPrimaryBrown,
                                  fontWeight: FontWeight.w600)),
                          Text('22.0 kHz',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _kPrimaryBrown,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    const Text(
                      'ปรับหาความถี่ที่สุนัขของคุณตอบสนองได้ดีที่สุด',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          color: _kPrimaryBrown,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Preset buttons ─────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLightPaw),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('ความถี่สำเร็จรูป',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _kDarkBrown)),
                    ),
                    Row(
                      children: _presets.map((p) {
                        final isSelected =
                            (_frequency - p.freq).abs() < 100;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                right: p == _presets.last ? 0 : 8),
                            child: GestureDetector(
                              onTap: () => _applyPreset(p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _kDarkBrown
                                      : _kSurface,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? _kDarkBrown
                                        : _kLightPaw,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(p.icon,
                                        size: 18,
                                        color: isSelected
                                            ? Colors.white
                                            : _kPrimaryBrown),
                                    const SizedBox(height: 5),
                                    Text(p.label,
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? Colors.white
                                                : _kDarkBrown)),
                                    Text(
                                        '${(p.freq / 1000).toStringAsFixed(1)}k',
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.white70
                                                : _kPrimaryBrown)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Info card ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kLightPaw),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _kFieldCream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.info_outline_rounded,
                          size: 14, color: _kPrimaryBrown),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'เสียงนกหวีดสุนัขอยู่ในช่วง 15–22 kHz\n'
                        'มนุษย์ได้ยินไม่ชัดหรือไม่ได้ยินเลย\n'
                        'กด "ฝึก" เพื่อเรียกความสนใจ กด "เรียก" เพื่อตามมา\n'
                        'กด "หยุด" เพื่อให้หยุดพฤติกรรม',
                        style: TextStyle(
                            fontSize: 12,
                            color: _kDarkBrown,
                            height: 1.6,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Whistle Button ───────────────────────────────────────────────────────────
class _WhistleButton extends StatelessWidget {
  final bool isPlaying;
  final Animation<double> pulseAnim;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _WhistleButton({
    required this.isPlaying,
    required this.pulseAnim,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Outer pulse ring ──────────────────────────────────────────────
        AnimatedBuilder(
          animation: pulseAnim,
          builder: (_, child) => Transform.scale(
            scale: isPlaying ? pulseAnim.value : 1.0,
            child: child,
          ),
          child: GestureDetector(
            onTapDown: (_) => onStart(),
            onTapUp: (_) => onStop(),
            onTapCancel: () => onStop(),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer glow ring (visible when playing)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying
                        ? _kPrimaryBrown.withOpacity(0.15)
                        : Colors.transparent,
                  ),
                ),
                // Main button circle
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPlaying ? _kDarkBrown : Colors.white,
                    border: Border.all(
                      color: isPlaying ? _kDarkBrown : _kLightPaw,
                      width: isPlaying ? 0 : 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kDarkBrown.withOpacity(
                            isPlaying ? 0.25 : 0.08),
                        blurRadius: isPlaying ? 24 : 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/whistle.png',
                        height: 56,
                        color: isPlaying ? Colors.white : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ── Status label ──────────────────────────────────────────────────
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            isPlaying ? 'กำลังเป่า...' : 'กดค้างเพื่อเป่านกหวีด',
            key: ValueKey(isPlaying),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isPlaying ? _kDarkBrown : _kPrimaryBrown,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // ── Sound wave indicator ──────────────────────────────────────────
        _SoundWave(isPlaying: isPlaying),
      ],
    );
  }
}

// ─── Animated Sound Wave bars ─────────────────────────────────────────────────
class _SoundWave extends StatefulWidget {
  final bool isPlaying;
  const _SoundWave({required this.isPlaying});

  @override
  State<_SoundWave> createState() => _SoundWaveState();
}

class _SoundWaveState extends State<_SoundWave>
    with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];
  static const _barCount = 7;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _barCount; i++) {
      final ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 300 + i * 60),
      );
      _ctrls.add(ctrl);
      _anims.add(Tween<double>(begin: 4, end: 22).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeInOut),
      ));
    }
  }

  @override
  void didUpdateWidget(covariant _SoundWave old) {
    super.didUpdateWidget(old);
    if (widget.isPlaying != old.isPlaying) {
      for (final c in _ctrls) {
        if (widget.isPlaying) {
          c.repeat(reverse: true);
        } else {
          c.animateTo(0, duration: const Duration(milliseconds: 200));
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_barCount, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Container(
              width: 4,
              height: _anims[i].value,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: widget.isPlaying
                    ? _kPrimaryBrown.withOpacity(0.7)
                    : _kLightPaw,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Preset model ─────────────────────────────────────────────────────────────
class _Preset {
  final String label;
  final int    freq;
  final IconData icon;
  const _Preset(this.label, this.freq, this.icon);
}