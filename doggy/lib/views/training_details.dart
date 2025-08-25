import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ใช้ iframe
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/training_service.dart';
import '../services/user_service.dart';
import '../routes/app_routes.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId;
  final String categoryId;
  final String? dogId; // รับมาจาก arguments ได้ แต่ไม่ให้เลือกในหน้านี้

  const TrainingDetailsPage({
    required this.documentId,
    required this.categoryId,
    this.dogId,
    super.key,
  });

  @override
  State<TrainingDetailsPage> createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final _auth = FirebaseAuth.instance;
  final _service = TrainingService(firestore: FirebaseFirestore.instance);
  final _userService = UserService();

  // --- ควบคุมวิดีโอ (iframe) ---
  YoutubePlayerController? _yt;
  StreamSubscription<Duration>? _posSub;                 // เวลา ณ ตอนนี้
  StreamSubscription<YoutubePlayerValue>? _valSub;       // ค่า value (มี playerState)
  int _lastSeconds = 0;

  bool _isLoading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? lesson;

  // progress
  User? _user;
  String? _dogId;
  int _currentStep = 1;
  Set<int> _completed = {};
  int _totalSteps = 0;

  // Intro gating
  bool _introWatched = false;
  int _introWatchSec = 0;
  static const int _INTRO_MIN_SEC = 20; // เกณฑ์เวลาที่ต้องดูอย่างน้อยก่อนเริ่ม Step

  // UX helpers
  final ScrollController _scroll = ScrollController();
  final List<GlobalKey> _stepKeys = [];
  final Set<int> _showInlineHint = {};

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _init();
  }

  @override
  void dispose() {
    try {
      _posSub?.cancel();
      _valSub?.cancel();
      _yt?.close(); // สำคัญ: iframe ใช้ close()
    } catch (_) {}
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    debugPrint('[TrainingDetails] init start: cat=${widget.categoryId}, doc=${widget.documentId}');
    try {
      // เลือก dogId: ถ้า constructor ส่งมาก็ใช้เลย ไม่งั้นใช้ activeDogId ที่ตั้งจากหน้าแรก
      _dogId = widget.dogId;
      if (_dogId == null && _user != null) {
        _dogId = await _userService.getActiveDogId();
      }
      debugPrint('[TrainingDetails] active dogId = $_dogId');

      // 1) ดึงบทเรียน
      final data = await _service.fetchLesson(
        categoryId: widget.categoryId,
        documentId: widget.documentId,
      );
      debugPrint('[TrainingDetails] lesson fetched: ${data != null}');
      if (data != null) {
        final id = _service.extractYoutubeId((data['video'] ?? '').toString());
        if (id.isNotEmpty) {
          // --- สร้าง controller แบบ iframe ---
          _yt = YoutubePlayerController.fromVideoId(
            videoId: id,
            autoPlay: false,
            params: const YoutubePlayerParams(
              showControls: true,
              showFullscreenButton: true,
              enableCaption: true,
              strictRelatedVideos: true,
              playsInline: true,
            ),
          );

          // --- ติดตามเวลา (Duration) ---
          _posSub?.cancel();
          _posSub = _yt!.getCurrentPositionStream().listen((dur) async {
            final sec = dur.inSeconds;
            if (sec > _lastSeconds) {
              _lastSeconds = sec;
              _introWatchSec = sec;

              if (!_introWatched &&
                  _introWatchSec >= _INTRO_MIN_SEC &&
                  _user != null &&
                  _dogId != null) {
                _introWatched = true;
                try {
                  await _service.updateIntroWatch(
                    userId: _user!.uid,
                    dogId: _dogId!,
                    documentId: widget.documentId,
                    watched: true,
                    watchSec: _introWatchSec,
                  );
                  if (mounted) setState(() {});
                } catch (_) {}
              }
            }
          });

          // --- ติดตามสถานะ player ผ่าน stream ของ controller ---
          _valSub?.cancel();
          _valSub = _yt!.stream.listen((value) async {
            if (!_introWatched &&
                value.playerState == PlayerState.ended &&
                _user != null &&
                _dogId != null) {
              _introWatched = true;
              try {
                await _service.updateIntroWatch(
                  userId: _user!.uid,
                  dogId: _dogId!,
                  documentId: widget.documentId,
                  watched: true,
                  watchSec: _introWatchSec,
                );
                if (mounted) setState(() {});
              } catch (_) {}
            }
          });
        }
      }

      // 2) โหลด progress (ต้องมี _user และ _dogId)
      if (_user != null && _dogId != null) {
        final p = await _service.loadProgress(
          userId: _user!.uid,
          dogId: _dogId!,
          documentId: widget.documentId,
          categoryId: widget.categoryId,
          lesson: data,
        );
        _currentStep = p.currentStep;
        _completed = p.completed;
        _totalSteps = p.totalSteps;
        _introWatched = p.introWatched;
        _introWatchSec = p.introWatchSec;
      } else {
        _totalSteps = ((data?['step'] is List) ? (data?['step'] as List) : const []).length;
      }

      if (!mounted) return;
      setState(() {
        lesson = data;
        _isLoading = false;
        _error = null;
      });

      // หากผ่าน intro แล้วค่อยเลื่อนหา current step; ถ้ายังไม่ผ่าน ให้โฟกัสวิดีโอ
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_introWatched) {
          _scrollToCurrentStep();
        } else {
          _scroll.animateTo(
            0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      });
    } catch (e, st) {
      debugPrint('[TrainingDetails] init error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = 'โหลดบทเรียนไม่สำเร็จ: $e';
        _isLoading = false;
      });
    }
  }

  List<_StepItem> _parseSteps(dynamic raw) {
    final List steps = (raw is List) ? raw : const [];
    final result = <_StepItem>[];
    for (var i = 0; i < steps.length; i++) {
      try {
        final m = (steps[i] is Map) ? Map<String, dynamic>.from(steps[i] as Map) : <String, dynamic>{};
        final img = (m['image'] ?? '').toString();
        String text = '';
        // รองรับ key: step1/step_1/Step 1 ...
        for (final k in m.keys) {
          if (k.toLowerCase().trim().startsWith('step')) {
            text = '${m[k]}';
            break;
          }
        }
        result.add(_StepItem(index1Based: i + 1, text: text, image: img));
      } catch (_) {
        // ถ้า step เพี้ยน ข้ามไป
      }
    }
    return result;
  }

  Future<void> _scrollToCurrentStep() async {
    if (!mounted) return;
    if (_currentStep <= 0 || _stepKeys.length < _currentStep) return;
    final key = _stepKeys[_currentStep - 1];
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 450),
      alignment: 0.1,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _confirmAndMarkDone(int stepNo) async {
    // หน้านี้ “ไม่ให้เลือกสุนัข” — ต้องมี activeDogId มาก่อน (ตั้งจากหน้าแรก)
    if (_user == null || _dogId == null) {
      _showNeedDogDialog();
      return;
    }

    // บังคับดูวิดีโอก่อนเริ่ม
    if (!_introWatched) {
      _showWatchIntroDialog();
      return;
    }

    // บังคับทำตามลำดับ
    if (stepNo != _currentStep) {
      if (!mounted) return;
      setState(() {
        _showInlineHint.add(stepNo);
      });
      _scrollToCurrentStep();
      return;
    }

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        bool c1 = false, c2 = false;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16, right: 16, top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ยืนยันความสำเร็จของขั้นตอนนี้',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (ctx, setS) {
                return Column(
                  children: [
                    CheckboxListTile(
                      value: c1,
                      onChanged: (v) => setS(() => c1 = v ?? false),
                      title: const Text('สุนัขทำได้ตามสัญญาณ 3 ครั้งติด'),
                    ),
                    CheckboxListTile(
                      value: c2,
                      onChanged: (v) => setS(() => c2 = v ?? false),
                      title: const Text('ไม่มีอาการเครียด/ลังเลชัดเจน'),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: (c1 && c2) ? () => Navigator.pop(ctx, true) : null,
                      child: const Text('ยืนยันสำเร็จ'),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );

    if (ok != true) return;

    // บันทึก
    if (!mounted) return;
    setState(() => _saving = true);
    _completed.add(stepNo);
    _currentStep = (stepNo < _totalSteps) ? stepNo + 1 : _totalSteps;

    try {
      await _service.saveProgress(
        userId: _user!.uid,
        dogId: _dogId!, // ผูกกับสุนัขที่ตั้งไว้จากหน้าแรก
        documentId: widget.documentId,
        categoryId: widget.categoryId,
        lesson: lesson,
        currentStep: _currentStep,
        completed: _completed,
        totalSteps: _totalSteps,
        lastStepDone: stepNo,
      );
    } catch (e) {
      debugPrint('[TrainingDetails] saveProgress error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    await Future.delayed(const Duration(milliseconds: 150));
    _scrollToCurrentStep();
  }

  void _showNeedDogDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เลือกสุนัขที่จะติดตาม'),
        content: const Text(
          'โปรดเลือกสุนัขจากหน้า “ข้อมูลสุนัขของคุณ” (หรือหน้าแรก) ก่อน แล้วกลับมาที่บทเรียนนี้',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.dogProfiles);
            },
            child: const Text('ไปตั้งค่าสุนัข'),
          ),
        ],
      ),
    );
  }

  void _showWatchIntroDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('โปรดดูวิดีโอแนะนำก่อน'),
        content: const Text('เพื่อความเข้าใจที่ถูกต้อง กรุณาดูวิดีโอแนะนำอย่างน้อยสั้น ๆ ก่อนเริ่มขั้นตอนที่ 1'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _scroll.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
            },
            child: const Text('ไปดูวิดีโอ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = lesson;
    final steps = _parseSteps(data?['step']);
    // เตรียม keys เท่ากับจำนวนขั้น
    if (_stepKeys.length != steps.length) {
      _stepKeys
        ..clear()
        ..addAll(List.generate(steps.length, (_) => GlobalKey()));
    }

    final total = steps.length;
    final finished = _completed.length.clamp(0, total);
    final progress = (total == 0) ? 0.0 : finished / total;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null)
              ? _ErrorView(message: _error!, onRetry: _init)
              : (data == null)
                  ? const Center(child: Text('ไม่พบบทเรียน'))
                  : CustomScrollView(
                      controller: _scroll,
                      slivers: [
                        SliverAppBar(
                          pinned: true,
                          backgroundColor: Colors.white,
                          elevation: 0.5,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                          centerTitle: true,
                          title: Text(
                            data['name']?.toString() ?? 'บทเรียนการฝึก',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (!_introWatched) {
                                  _scroll.animateTo(0,
                                      duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                                } else {
                                  _scrollToCurrentStep();
                                }
                              },
                              child: Text(!_introWatched ? 'ไปดูวิดีโอ' : 'ไปขั้นตอนที่ $_currentStep'),
                            ),
                          ],
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(54),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _ProgressBar(
                                progress: progress,
                                label: 'ความคืบหน้า ${(progress * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                          ),
                        ),

                        // Callout: ยังไม่ได้เลือกสุนัข
                        if (_user != null && _dogId == null)
                          SliverToBoxAdapter(
                            child: Container(
                              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3CD),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFFEEBA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.pets_outlined),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text('ยังไม่ได้เลือกสุนัข • จะไม่บันทึกความคืบหน้า'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
                                    child: const Text('เลือกสุนัข'),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // วิดีโอหัวบท / ภาพ
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: _yt != null
                                  ? YoutubePlayer(controller: _yt!)
                                  : ((data['image'] ?? '').toString().isNotEmpty)
                                      ? Image.network(
                                          (data['image'] ?? '').toString(),
                                          height: 200,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          loadingBuilder: (_, child, progress) {
                                            if (progress == null) return child;
                                            return Container(height: 200, color: Colors.black12);
                                          },
                                          errorBuilder: (_, __, ___) => _grayHeader(),
                                        )
                                      : _grayHeader(),
                            ),
                          ),
                        ),

                        // สรุปสั้น ๆ + คำอธิบาย
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('ความยาก: ${data['difficulty'] ?? '-'}'),
                                    Text('ระยะเวลา: ${data['duration'] ?? '-'} นาที'),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if ((data['description'] ?? '').toString().isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4EDE4),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text((data['description'] ?? '').toString()),
                                  ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        // Step Navigator (ชิป 1..N)
                        SliverToBoxAdapter(child: _stepNavigator(steps)),

                        // รายการ Step (การ์ด)
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final item = steps[i];
                              return Padding(
                                padding: EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 16),
                                child: _StepCard(
                                  key: _stepKeys[i],
                                  item: item,
                                  isCompleted: _completed.contains(item.index1Based),
                                  isCurrent: _currentStep == item.index1Based,
                                  showInlineHint: _showInlineHint.contains(item.index1Based),
                                  saving: _saving,
                                  onStart: () {
                                    if (!_introWatched) {
                                      _showWatchIntroDialog();
                                      return;
                                    }
                                    if (item.index1Based != _currentStep) {
                                      if (!mounted) return;
                                      setState(() => _showInlineHint.add(item.index1Based));
                                      _scrollToCurrentStep();
                                    }
                                  },
                                  onDone: () {
                                    if (!_introWatched) {
                                      _showWatchIntroDialog();
                                      return;
                                    }
                                    _confirmAndMarkDone(item.index1Based);
                                  },
                                ),
                              );
                            },
                            childCount: steps.length,
                          ),
                        ),

                        // จบทั้งหมด
                        if (total > 0 && finished == total)
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 40),
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('เยี่ยมมาก! จบบทเรียนนี้แล้ว')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34C759),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child:
                                      const Text('สิ้นสุดบทเรียน', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }

  Widget _stepNavigator(List<_StepItem> steps) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: steps.map((s) {
          final isDone = _completed.contains(s.index1Based);
          final isCur = _currentStep == s.index1Based;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isCur,
              label: Text(isDone ? '${s.index1Based} ✓' : '${s.index1Based}'),
              onSelected: (_) {
                if (!_introWatched) {
                  _showWatchIntroDialog();
                  return;
                }
                if (isCur) {
                  _scrollToCurrentStep();
                } else {
                  // ถ้ายังไม่ถึงคิว → แสดง hint และเลื่อนกลับ current
                  setState(() => _showInlineHint.add(s.index1Based));
                  _scrollToCurrentStep();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _grayHeader() => Container(
        height: 200,
        width: double.infinity,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.ondemand_video, size: 56),
      );
}

// ----------------- helpers & widgets -----------------

class _StepItem {
  final int index1Based;
  final String text;
  final String image;
  _StepItem({required this.index1Based, required this.text, required this.image});
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  const _ProgressBar({required this.progress, required this.label, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEBC7A6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress.clamp(0, 1),
                minHeight: 12,
                backgroundColor: const Color(0xFFD5B299),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final _StepItem item;
  final bool isCompleted;
  final bool isCurrent;
  final bool showInlineHint;
  final bool saving;
  final VoidCallback onStart;
  final VoidCallback onDone;

  const _StepCard({
    super.key,
    required this.item,
    required this.isCompleted,
    required this.isCurrent,
    required this.showInlineHint,
    required this.saving,
    required this.onStart,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    String badge;
    Widget actionBtn;

    if (isCompleted) {
      bg = const Color(0xFFE5F6E8); // เขียวอ่อน
      badge = 'สำเร็จแล้ว ✓';
      actionBtn = ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5F6E8),
          foregroundColor: const Color(0xFF2E7D32), // เขียวเข้ม
          disabledBackgroundColor: const Color(0xFFE5F6E8),
          disabledForegroundColor: const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        child: const Text('สำเร็จแล้ว', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    } else if (isCurrent) {
      bg = const Color(0xFFFFF9E6); // เหลืองพาสเทล
      badge = 'ขั้นตอนปัจจุบัน ⏳';
      actionBtn = ElevatedButton(
        onPressed: saving ? null : onDone,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFA5D6A7), // เขียวพาสเทล
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
        ),
        child: Text(
          saving ? 'กำลังบันทึก...' : 'ทำสำเร็จแล้ว',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    } else {
      bg = const Color(0xFFE3F2FD); // ฟ้าอ่อน
      badge = 'รอคิว ▶️';
      actionBtn = ElevatedButton(
        onPressed: onStart,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF90CAF9),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          elevation: 0,
        ),
        child: const Text('เริ่มฝึก', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (item.image.isNotEmpty)
                ? Image.network(
                    item.image,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback(),
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(height: 170, color: Colors.black12);
                    },
                  )
                : _imgFallback(),
          ),
          const SizedBox(height: 10),
          Text('ขั้นตอนที่ ${item.index1Based}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(item.text, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              actionBtn,
            ],
          ),

          // Inline hint เมื่อกดผิดลำดับ
          if (showInlineHint && !isCurrent && !isCompleted) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ทำทีละขั้น กรุณารอให้ถึง “ขั้นตอนที่กำลังทำ” ก่อน '
                      'คุณสามารถใช้ปุ่มด้านบนเพื่อไปยังขั้นตอนปัจจุบันได้ทันที',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        height: 170,
        width: double.infinity,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported, size: 48),
      );

  // สไตล์ปุ่มแยกสถานะให้คอนทราสต์ชัด
  ButtonStyle _btnStylePrimary() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF34C759),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      );

  ButtonStyle _btnStyleDisabled() => ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade300,
        foregroundColor: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      );

  ButtonStyle _btnStyleOutline() => OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.black26),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
