import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import '../widgets/bottom_navbar.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kBg           = Color(0xFFF7EFE7);
const _kSurface      = Color(0xFFEFE2D3);
const _kFieldCream   = Color(0xFFEAD8C8);
const _kLightPaw     = Color(0xFFE8D5C0);
const _kPrimaryBrown = Color(0xFFB08968);
const _kDarkBrown    = Color(0xFF6D4C41);

class ClickerPage extends StatefulWidget {
  const ClickerPage({super.key});

  @override
  State<ClickerPage> createState() => _ClickerPageState();
}

class _ClickerPageState extends State<ClickerPage>
    with TickerProviderStateMixin {
  // ── Audio ────────────────────────────────────────────────────────────────
  final AudioPlayer        _audioPlayer = AudioPlayer();
  final FlutterSoundPlayer _synthPlayer = FlutterSoundPlayer();
  bool _useSynthFallback = false;
  bool _soundLock        = false; // ✅ ป้องกันเสียงซ้อนกัน

  // ── State ────────────────────────────────────────────────────────────────
  bool _isPressed    = false;
  int  _clickCount   = 0;
  int  _sessionCount = 0; // นับรอบการฝึก (ทุก 10 click)

  // ── Animations ───────────────────────────────────────────────────────────
  late AnimationController _rippleCtrl;
  late AnimationController _scaleCtrl;
  late Animation<double>   _rippleAnim;
  late Animation<double>   _scaleAnim;

  // ── Clicker sound settings ────────────────────────────────────────────────
  double _clickVolume  = 1.0;
  bool   _doubleClick  = false; // เสียง 2 ครั้งติดกัน (double-click mode)

  @override
  void initState() {
    super.initState();

    // ── Ripple animation ─────────────────────────────────────────────────
    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _rippleAnim = Tween<double>(begin: 0.8, end: 1.6).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );

    // ── Scale animation ──────────────────────────────────────────────────
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeOut),
    );

    _synthPlayer.openPlayer();
  }

  @override
  void dispose() {
    _rippleCtrl.dispose();
    _scaleCtrl.dispose();
    _audioPlayer.dispose();
    _synthPlayer.stopPlayer();
    _synthPlayer.closePlayer();
    super.dispose();
  }

  // ── Generate realistic clicker sound (PCM synthesis) ─────────────────────
  // เสียงคลิกเกอร์จริงๆ คือ metal strip snap:
  // - sharp attack noise burst (< 5ms)
  // - short metallic resonance (~800-2000 Hz)
  // - rapid decay
  Future<Uint8List> _generateClickerPCM() async {
    const sampleRate  = 44100;
    const durationMs  = 80; // คลิกเกอร์สั้นมาก
    const sampleCount = (sampleRate * durationMs) ~/ 1000;

    final byteData = ByteData(sampleCount * 2);
    final rng      = Random();

    for (int i = 0; i < sampleCount; i++) {
      final double t = i / sampleRate;

      // ── Exponential decay envelope ────────────────────────────────────
      final double decay = exp(-t * 80.0); // decay ชัน

      // ── Metallic click: noise burst + two resonant frequencies ────────
      final double noise     = (rng.nextDouble() * 2 - 1) * 0.35;
      final double tone1     = sin(2 * pi * 1200 * t) * 0.45; // main click tone
      final double tone2     = sin(2 * pi * 1800 * t) * 0.20; // harmonic
      final double transient = sin(2 * pi * 3500 * t) * 0.10; // click transient

      double sample = (noise + tone1 + tone2 + transient) * decay;
      sample = sample.clamp(-1.0, 1.0) * _clickVolume;

      byteData.setInt16(i * 2, (sample * 30000).toInt(), Endian.little);
    }

    return byteData.buffer.asUint8List();
  }

  // ── Play clicker sound ────────────────────────────────────────────────────
  Future<void> _playClick() async {
    // ✅ ถ้าเสียงก่อนหน้ายังไม่จบ ให้ข้ามไป (ป้องกันซ้อน)
    if (_soundLock) return;
    _soundLock = true;

    try {
      if (!_useSynthFallback) {
        await _audioPlayer.stop();
        await _audioPlayer.setVolume(_clickVolume);
        await _audioPlayer.play(AssetSource('sounds/clicker_sound.wav'));
        // รอให้เสียงจบก่อน unlock (clicker_sound.wav ~80-100ms)
        await Future.delayed(const Duration(milliseconds: 120));
      }
    } catch (_) {
      _useSynthFallback = true;
    }

    // ถ้า asset ไม่มีหรือ error ใช้ synth เสมอ
    if (_useSynthFallback) {
      try {
        // ✅ stop ก่อนเสมอ ป้องกัน FlutterSound ค้าง
        await _synthPlayer.stopPlayer();
        final pcm = await _generateClickerPCM();
        await _synthPlayer.startPlayer(
          fromDataBuffer: pcm,
          codec: Codec.pcm16,
          sampleRate: 44100,
          numChannels: 1,
          whenFinished: () async {
            if (_doubleClick && mounted) {
              // double click: เล่นซ้ำครั้งที่ 2 หลัง 80ms
              await Future.delayed(const Duration(milliseconds: 80));
              if (mounted) {
                final pcm2 = await _generateClickerPCM();
                await _synthPlayer.startPlayer(
                  fromDataBuffer: pcm2,
                  codec: Codec.pcm16,
                  sampleRate: 44100,
                  numChannels: 1,
                );
              }
            }
          },
        );
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    } else if (_doubleClick) {
      await Future.delayed(const Duration(milliseconds: 90));
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource('sounds/clicker_sound.wav'));
        await Future.delayed(const Duration(milliseconds: 120));
      } catch (_) {}
    }

    _soundLock = false; // ✅ unlock หลังเสียงจบ
  }

  // ── Press handlers ────────────────────────────────────────────────────────
  Future<void> _onPressStart() async {
    if (_isPressed) return;
    HapticFeedback.mediumImpact();

    setState(() {
      _isPressed = true;
      _clickCount++;
      if (_clickCount % 10 == 0) _sessionCount++;
    });

    // Animations
    _scaleCtrl.forward();
    _rippleCtrl.forward(from: 0);

    await _playClick();
  }

  void _onPressEnd() {
    if (!_isPressed) return;
    _scaleCtrl.reverse();
    setState(() => _isPressed = false);
  }

  // ── Reset counter ─────────────────────────────────────────────────────────
  void _resetCounter() {
    HapticFeedback.selectionClick();
    setState(() {
      _clickCount   = 0;
      _sessionCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Clicker Training',
            style: TextStyle(
                color: _kDarkBrown, fontWeight: FontWeight.w800,
                fontSize: 16, letterSpacing: -0.2)),
        actions: [
          // Reset button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: _resetCounter,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLightPaw),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        size: 13, color: _kPrimaryBrown),
                    SizedBox(width: 4),
                    Text('รีเซ็ต',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _kDarkBrown)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
      body: SafeArea(
        child: SingleChildScrollView(          // ✅ แก้ overflow
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [

              // ── Stats row ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.touch_app_rounded,
                      label: 'คลิกทั้งหมด',
                      value: '$_clickCount',
                      accent: _kDarkBrown,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.repeat_rounded,
                      label: 'รอบการฝึก',
                      value: '$_sessionCount',
                      accent: const Color(0xFF4C9A5C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Progress to next session (10 clicks)
                  Expanded(
                    child: _ProgressCard(
                      current: _clickCount % 10,
                      total:   10,
                    ),
                  ),
                ],
              ),

              // ── Clicker button ──────────────────────────────────────────
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple effect
                    AnimatedBuilder(
                      animation: _rippleAnim,
                      builder: (_, __) => Opacity(
                        opacity: _rippleCtrl.isAnimating
                            ? (1 - _rippleCtrl.value) * 0.4
                            : 0,
                        child: Transform.scale(
                          scale: _rippleAnim.value,
                          child: Container(
                            width: 200, height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _kPrimaryBrown,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Clicker image
                    AnimatedBuilder(
                      animation: _scaleAnim,
                      builder: (_, child) => Transform.scale(
                        scale: _scaleAnim.value,
                        child: child,
                      ),
                      child: GestureDetector(
                        onTapDown: (_) => _onPressStart(),
                        onTapUp:   (_) => _onPressEnd(),
                        onTapCancel: _onPressEnd,
                        child: Image.asset(
                          _isPressed
                              ? 'assets/images/clicker_use.png'
                              : 'assets/images/clicker_original.png',
                          width: 260,
                          height: 260,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Status label ────────────────────────────────────────────
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: Text(
                  _isPressed ? 'Click! 🎯' : 'แตะเพื่อส่งเสียงคลิก',
                  key: ValueKey(_isPressed),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _isPressed ? _kDarkBrown : _kPrimaryBrown,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'ใช้เสริมแรงเชิงบวกทันทีที่สุนัขทำพฤติกรรมที่ถูกต้อง',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _kPrimaryBrown,
                  fontWeight: FontWeight.w500,
                ),
              ),

              // ── Settings card ────────────────────────────────────────────
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kLightPaw),
                ),
                child: Column(
                  children: [
                    // Volume
                    Row(
                      children: [
                        const Icon(Icons.volume_up_rounded,
                            size: 16, color: _kPrimaryBrown),
                        const SizedBox(width: 8),
                        const Text('ระดับเสียง',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _kDarkBrown)),
                        const Spacer(),
                        Text(
                          '${(_clickVolume * 100).round()}%',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _kPrimaryBrown),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor:   _kDarkBrown,
                        inactiveTrackColor: _kFieldCream,
                        thumbColor:         _kDarkBrown,
                        overlayColor:       _kPrimaryBrown.withOpacity(0.12),
                        trackHeight:        4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _clickVolume,
                        min: 0.1, max: 1.0, divisions: 9,
                        onChanged: (v) =>
                            setState(() => _clickVolume = v),
                      ),
                    ),

                    // Divider
                    Divider(color: _kLightPaw, thickness: 1, height: 16),

                    // Double-click toggle
                    Row(
                      children: [
                        const Icon(Icons.double_arrow_rounded,
                            size: 16, color: _kPrimaryBrown),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('โหมด Double-click',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _kDarkBrown)),
                              Text('คลิก 2 ครั้งติดกัน (สำหรับสัญญาณพิเศษ)',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: _kPrimaryBrown,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _doubleClick,
                          onChanged: (v) =>
                              setState(() => _doubleClick = v),
                          activeColor: _kDarkBrown,
                          activeTrackColor: _kFieldCream,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tip card ─────────────────────────────────────────────────
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _kLightPaw),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _kFieldCream,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.lightbulb_outline_rounded,
                          size: 13, color: _kPrimaryBrown),
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'คลิกทันทีที่สุนัขทำพฤติกรรมถูกต้อง\n'
                        'แล้วตามด้วยรางวัลภายใน 3 วินาที\n'
                        'ฝึกอย่างน้อย 10 ครั้งต่อรอบเพื่อผลลัพธ์ที่ดี',
                        style: TextStyle(
                            fontSize: 11,
                            color: _kDarkBrown,
                            height: 1.65,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),    // SafeArea
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  final Color    accent;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLightPaw),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accent)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryBrown)),
        ],
      ),
    );
  }
}

// ─── Progress Card ────────────────────────────────────────────────────────────
class _ProgressCard extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressCard({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = current / total;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kLightPaw),
      ),
      child: Column(
        children: [
          const Icon(Icons.track_changes_rounded,
              size: 16, color: _kPrimaryBrown),
          const SizedBox(height: 5),
          Text('$current/$total',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _kDarkBrown)),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: _kFieldCream,
              valueColor: const AlwaysStoppedAnimation(_kPrimaryBrown),
            ),
          ),
          const SizedBox(height: 3),
          const Text('ถึงรอบ',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _kPrimaryBrown)),
        ],
      ),
    );
  }
}