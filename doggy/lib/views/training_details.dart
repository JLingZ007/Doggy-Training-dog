// lib/pages/training_details_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../services/training_service.dart';
import '../services/user_service.dart';
import '../routes/app_routes.dart';

import '../models/step_item.dart';
import '../widgets/training/progress_bar.dart';
import '../widgets/training/error_view.dart';
import '../widgets/training/video_header.dart';
import '../widgets/training/lesson_meta.dart';
import '../widgets/training/need_dog_callout.dart';
import '../widgets/training/step_navigator.dart';
import '../widgets/training/step_card.dart';
import '../widgets/training/_dialogs.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId;
  final String categoryId;
  final String? dogId;
  const TrainingDetailsPage({
    super.key,
    required this.documentId,
    required this.categoryId,
    this.dogId,
  });

  @override
  State<TrainingDetailsPage> createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final _auth = FirebaseAuth.instance;
  final _service = TrainingService(firestore: FirebaseFirestore.instance);
  final _userService = UserService();

  // Youtube (iframe)
  YoutubePlayerController? _yt;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<YoutubePlayerValue>? _valSub;
  int _lastSeconds = 0;

  // state
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

  // intro gating
  bool _introWatched = false;
  int _introWatchSec = 0;
  static const int _INTRO_MIN_SEC = 20;

  // UI helpers
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
      _yt?.close();
    } catch (_) {}
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      // เลือก dogId: จาก args หรือ activeDogId
      _dogId = widget.dogId ?? await _userService.getActiveDogId();

      // 1) ดึงบทเรียน
      final data = await _service.fetchLesson(
        categoryId: widget.categoryId,
        documentId: widget.documentId,
      );

      if (data != null) {
        final id = _service.extractYoutubeId((data['video'] ?? '').toString());
        if (id.isNotEmpty) {
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

          // track time
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
                await _service.updateIntroWatch(
                  userId: _user!.uid,
                  dogId: _dogId!,
                  documentId: widget.documentId,
                  watched: true,
                  watchSec: _introWatchSec,
                );
                if (mounted) setState(() {});
              }
            }
          });

          // track ended state
          _valSub?.cancel();
          _valSub = _yt!.stream.listen((value) async {
            if (!_introWatched &&
                value.playerState == PlayerState.ended &&
                _user != null &&
                _dogId != null) {
              _introWatched = true;
              await _service.updateIntroWatch(
                userId: _user!.uid,
                dogId: _dogId!,
                documentId: widget.documentId,
                watched: true,
                watchSec: _introWatchSec,
              );
              if (mounted) setState(() {});
            }
          });
        }
      }

      // 2) โหลด progress
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
        _totalSteps =
            ((data?['step'] is List) ? (data?['step'] as List) : const [])
                .length;
      }

      if (!mounted) return;
      setState(() {
        lesson = data;
        _isLoading = false;
        _error = null;
      });

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

  List<StepItem> _parseSteps(dynamic raw) {
    final List steps = (raw is List) ? raw : const [];
    final result = <StepItem>[];
    for (var i = 0; i < steps.length; i++) {
      try {
        final m = (steps[i] is Map)
            ? Map<String, dynamic>.from(steps[i] as Map)
            : <String, dynamic>{};
        final img = (m['image'] ?? '').toString();
        String text = '';
        for (final k in m.keys) {
          if (k.toLowerCase().trim().startsWith('step')) {
            text = '${m[k]}';
            break;
          }
        }
        result.add(StepItem(index1Based: i + 1, text: text, image: img));
      } catch (_) {}
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
    // ต้องมีสุนัขที่ถูกเลือกไว้ก่อน (ตั้งจากหน้าแรก)
    if (_user == null || _dogId == null) {
      await showNeedDogDialog(
        context,
        () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
      );
      return;
    }

    // ต้องดู intro ก่อน
    if (!_introWatched) {
      await showWatchIntroDialog(
        context,
        () => _scroll.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        ),
      );
      return;
    }

    // ต้องทำตามลำดับ
    if (stepNo != _currentStep) {
      setState(() => _showInlineHint.add(stepNo));
      _scrollToCurrentStep();
      return;
    }

    final ok = await showConfirmStepDoneSheet(context);
    if (ok != true) return;

    setState(() => _saving = true);
    _completed.add(stepNo);
    _currentStep = (stepNo < _totalSteps) ? stepNo + 1 : _totalSteps;

    try {
      await _service.saveProgress(
        userId: _user!.uid,
        dogId: _dogId!,
        documentId: widget.documentId,
        categoryId: widget.categoryId,
        lesson: lesson,
        currentStep: _currentStep,
        completed: _completed,
        totalSteps: _totalSteps,
        lastStepDone: stepNo,
      );
    } catch (e) {
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

  // ===== เพิ่ม: ปุ่มลัดไปเมนูคลิกเกอร์/นกหวีด =====
  void _openClicker() {
    Navigator.pushNamed(context, AppRoutes.clicker); // เปลี่ยนเป็น route จริงของโปรเจกต์ได้
  }

  void _openWhistle() {
    Navigator.pushNamed(context, AppRoutes.whistle);
  }

  @override
  Widget build(BuildContext context) {
    final data = lesson;
    final steps = _parseSteps(data?['step']);

    // เตรียม keys สำหรับเลื่อน-โฟกัส step
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
              ? ErrorView(message: _error!, onRetry: _init)
              : (data == null)
                  ? const Center(child: Text('ไม่พบบทเรียน'))
                  : CustomScrollView(
                      controller: _scroll,
                      slivers: [
                        // ===== AppBar + Progress =====
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
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                if (!_introWatched) {
                                  _scroll.animateTo(
                                    0,
                                    duration: const Duration(milliseconds: 400),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _scrollToCurrentStep();
                                }
                              },
                              child: Text(
                                !_introWatched
                                    ? 'ไปดูวิดีโอ'
                                    : 'ไปขั้นตอนที่ $_currentStep',
                              ),
                            ),
                          ],
                          bottom: PreferredSize(
                            preferredSize: const Size.fromHeight(54),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: ProgressBar(
                                progress: progress,
                                label: 'ความคืบหน้า ${(progress * 100).toStringAsFixed(0)}%',
                              ),
                            ),
                          ),
                        ),

                        // ===== Callout: ยังไม่ได้เลือกสุนัข =====
                        if (_user != null && _dogId == null)
                          SliverToBoxAdapter(
                            child: NeedDogCallout(
                              onSelectDog: () =>
                                  Navigator.pushNamed(context, AppRoutes.dogProfiles),
                            ),
                          ),

                        // ===== วิดีโอหัวบท / ภาพสำรอง =====
                        SliverToBoxAdapter(
                          child: VideoHeader(
                            controller: _yt,
                            imageUrlFallback: (data['image'] ?? '').toString(),
                          ),
                        ),

                        // ===== สรุป/คำอธิบาย =====
                        SliverToBoxAdapter(
                          child: LessonMeta(
                            difficulty: (data['difficulty'] ?? '-').toString(),
                            durationMin: (data['duration'] ?? '-').toString(),
                            description: (data['description'] ?? '').toString(),
                          ),
                        ),

                        // ===== Step Navigator =====
                        SliverToBoxAdapter(
                          child: StepNavigator(
                            steps: steps,
                            completed: _completed,
                            currentStep: _currentStep,
                            introWatched: _introWatched,
                            onNeedWatchIntro: () => showWatchIntroDialog(
                              context,
                              () => _scroll.animateTo(
                                0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              ),
                            ),
                            onJumpToCurrent: _scrollToCurrentStep,
                            onTapLocked: (s) {
                              setState(() => _showInlineHint.add(s));
                              _scrollToCurrentStep();
                            },
                          ),
                        ),

                        // ===== Step list =====
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final item = steps[i];
                              return Padding(
                                padding:
                                    EdgeInsets.fromLTRB(16, i == 0 ? 8 : 0, 16, 16),
                                child: StepCard(
                                  key: _stepKeys[i],
                                  item: item,
                                  isCompleted: _completed.contains(item.index1Based),
                                  isCurrent: _currentStep == item.index1Based,
                                  showInlineHint: _showInlineHint.contains(item.index1Based),
                                  saving: _saving,
                                  onStart: () {
                                    if (!_introWatched) {
                                      showWatchIntroDialog(
                                        context,
                                        () => _scroll.animateTo(
                                          0,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        ),
                                      );
                                      return;
                                    }
                                    if (item.index1Based != _currentStep) {
                                      setState(
                                          () => _showInlineHint.add(item.index1Based));
                                      _scrollToCurrentStep();
                                    }
                                  },
                                  onDone: () {
                                    if (!_introWatched) {
                                      showWatchIntroDialog(
                                        context,
                                        () => _scroll.animateTo(
                                          0,
                                          duration: const Duration(milliseconds: 400),
                                          curve: Curves.easeInOut,
                                        ),
                                      );
                                      return;
                                    }
                                    _confirmAndMarkDone(item.index1Based);
                                  },

                                  // ===== ส่ง callback สำหรับปุ่มลัดเครื่องมือ =====
                                  onOpenClicker: _openClicker,
                                  onOpenWhistle: _openWhistle,
                                ),
                              );
                            },
                            childCount: steps.length,
                          ),
                        ),

                        // ===== ปุ่มจบบทเรียน =====
                        if (total > 0 && finished == total)
                          SliverToBoxAdapter(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12, bottom: 40),
                                child: ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('เยี่ยมมาก! จบบทเรียนนี้แล้ว'),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF34C759),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 36,
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'สิ้นสุดบทเรียน',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
