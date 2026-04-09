import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/training_service.dart';
import '../services/user_service.dart';
import '../routes/app_routes.dart';
import '../services/youtube_service.dart';

import '../models/step_item.dart';
import '../widgets/training/progress_bar.dart';
import '../widgets/training/error_view.dart';
import '../widgets/training/lesson_meta.dart';
import '../widgets/training/need_dog_callout.dart';
import '../widgets/training/step_navigator.dart';
import '../widgets/training/step_card.dart';
import '../widgets/training/_dialogs.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const kBgColor      = Color(0xFFF7EFE7);
const kSurfaceCream = Color(0xFFEFE2D3);
const kFieldCream   = Color(0xFFEAD8C8);
const kCancelColor  = Color(0xFF7C5959);
const kPrimaryBrown = Color(0xFFB08968);
const kDarkBrown    = Color(0xFF6D4C41);
const kLightPaw     = Color(0xFFE8D5C0);
const kSuccessGreen = Color(0xFF4C9A5C);

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
  final _auth        = FirebaseAuth.instance;
  final _service     = TrainingService(firestore: FirebaseFirestore.instance);
  final _userService = UserService();

  bool     _isLoading   = true;
  bool     _saving      = false;
  String?  _error;
  Map<String, dynamic>? lesson;

  User?    _user;
  String?  _dogId;
  int      _currentStep  = 1;
  Set<int> _completed    = {};
  int      _totalSteps   = 0;
  bool     _introWatched = false;

  final ScrollController _scroll   = ScrollController();
  final List<GlobalKey>  _stepKeys = [];
  final Set<int> _showInlineHint   = {};

  // ✅ Key สำหรับ scroll ไปที่ video thumbnail
  final GlobalKey _videoKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _init();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    try {
      _dogId = widget.dogId ?? await _userService.getActiveDogId();

      final data = await _service.fetchLesson(
        categoryId: widget.categoryId,
        documentId: widget.documentId,
      );

      if (_user != null && _dogId != null) {
        final p = await _service.loadProgress(
          userId: _user!.uid,
          dogId: _dogId!,
          documentId: widget.documentId,
          categoryId: widget.categoryId,
          lesson: data,
        );
        _currentStep  = p.currentStep;
        _completed    = p.completed;
        _totalSteps   = p.totalSteps;
        _introWatched = p.introWatched;
      } else {
        _totalSteps =
            ((data?['step'] is List) ? (data?['step'] as List) : const [])
                .length;
      }

      if (!mounted) return;
      setState(() {
        lesson     = data;
        _isLoading = false;
        _error     = null;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_introWatched) {
          _scrollToCurrentStep();
        } else {
          _scrollToVideo();
        }
      });
    } catch (e, st) {
      debugPrint('[TrainingDetails] init error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error     = 'โหลดบทเรียนไม่สำเร็จ: $e';
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

  // ✅ Scroll ไปที่ video thumbnail
  Future<void> _scrollToVideo() async {
    if (!mounted) return;
    final ctx = _videoKey.currentContext;
    if (ctx == null) {
      _scroll.animateTo(0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut);
      return;
    }
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      alignment: 0.0,
      curve: Curves.easeInOut,
    );
  }

  // ✅ Scroll ไปที่ current step card
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

  // ✅ ปุ่ม AppBar action:
  //    - ยังไม่ดูวิดีโอ → เปิด YouTube + scroll ไป video
  //    - ดูแล้ว → scroll ไป current step card
  void _onAppBarActionTap() {
    if (!_introWatched) {
      _openVideo();
    } else {
      _scrollToCurrentStep();
    }
  }

  // ✅ เปิดวิดีโอและ mark introWatched
  void _openVideo() {
    final videoId = (lesson?['video'] ?? '').toString();
    if (videoId.isEmpty) return;
    YoutubeService.openVideo(videoId);
    if (!mounted) return;
    setState(() => _introWatched = true);
    if (_user != null && _dogId != null) {
      _service.updateIntroWatch(
        userId: _user!.uid,
        dogId: _dogId!,
        documentId: widget.documentId,
        watched: true,
        watchSec: 0,
      );
    }
  }

  Future<void> _confirmAndMarkDone(int stepNo) async {
    if (_user == null || _dogId == null) {
  await showNeedDogDialog(
    context,
    () async {
      // ✅ รอ result จาก dog_profiles
      final changed = await Navigator.pushNamed(
          context, AppRoutes.dogProfiles);
      if (changed == true && mounted) {
        // reload ข้อมูลทั้งหมดรวมถึง dogId ใหม่
        _init();
      }
    },
  );
  return;
}
    if (!_introWatched) {
      // ✅ ส่ง _scrollToVideo แทน anonymous function
      await showWatchIntroDialog(context, _scrollToVideo);
      return;
    }
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
          SnackBar(
            content: Text('บันทึกไม่สำเร็จ: $e'),
            backgroundColor: kCancelColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    await Future.delayed(const Duration(milliseconds: 150));
    _scrollToCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final data  = lesson;
    final steps = _parseSteps(data?['step']);

    if (_stepKeys.length != steps.length) {
      _stepKeys
        ..clear()
        ..addAll(List.generate(steps.length, (_) => GlobalKey()));
    }

    final total     = steps.length;
    final finished  = _completed.length.clamp(0, total);
    final progress  = (total == 0) ? 0.0 : finished / total;
    final isAllDone = total > 0 && finished == total;

    return Scaffold(
      backgroundColor: kBgColor,
      body: _isLoading
          ? const _LoadingView()
          : (_error != null)
              ? ErrorView(message: _error!, onRetry: _init)
              : (data == null)
                  ? const Center(child: Text('ไม่พบบทเรียน'))
                  : CustomScrollView(
                      controller: _scroll,
                      slivers: [

                        // ── SliverAppBar ──────────────────────────────────
                        SliverAppBar(
  pinned: true,
  backgroundColor: Colors.white,
  elevation: 0,
  centerTitle: true,
  toolbarHeight: 56,
  leadingWidth: 56,
  leading: Center(
    child: _CircleIconBtn(
      icon: Icons.arrow_back_ios_new_rounded,
      onTap: () => Navigator.pop(context),
    ),
  ),
  title: Text(
    data['name']?.toString() ?? 'บทเรียนการฝึก',
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: kDarkBrown,
      fontWeight: FontWeight.w800,
      fontSize: 16,
      letterSpacing: -0.2,
    ),
  ),
  actions: [
    Center(
      child: GestureDetector(
        onTap: _onAppBarActionTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(
              horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: !_introWatched ? kDarkBrown : kSurfaceCream,
            borderRadius: BorderRadius.circular(20),
            border: _introWatched
                ? Border.all(color: kLightPaw)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                !_introWatched
                    ? Icons.play_circle_outline_rounded
                    : Icons.navigation_rounded,
                size: 13,
                color: !_introWatched ? Colors.white : kDarkBrown,
              ),
              const SizedBox(width: 5),
              Text(
                !_introWatched
                    ? 'ดูวิดีโอ'
                    : 'ขั้นที่ $_currentStep',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: !_introWatched
                      ? Colors.white
                      : kDarkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(52),
    child: _ProgressSection(
      progress: progress,
      finished: finished,
      total: total,
    ),
  ),
),

                        // ── Need Dog Banner ───────────────────────────────
                        if (_user != null && _dogId == null)
                          SliverToBoxAdapter(
                            child: NeedDogCallout(
                              onSelectDog: () => Navigator.pushNamed(
                                  context, AppRoutes.dogProfiles),
                            ),
                          ),

                        // ── Video Thumbnail ✅ ใส่ key ─────────────────────
                        SliverToBoxAdapter(
                          child: _VideoThumbnail(
                            key: _videoKey,
                            videoId: (data['video'] ?? '').toString(),
                            introWatched: _introWatched,
                            onTap: _openVideo,
                          ),
                        ),

                        // ── Lesson Meta ───────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                            child: LessonMeta(
                              difficulty:
                                  (data['difficulty'] ?? '-').toString(),
                              durationMin:
                                  (data['duration'] ?? '-').toString(),
                              description:
                                  (data['description'] ?? '').toString(),
                            ),
                          ),
                        ),

                        // ── Step Navigator ────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                            child: StepNavigator(
                              steps: steps,
                              completed: _completed,
                              currentStep: _currentStep,
                              introWatched: _introWatched,
                              // ✅ ส่ง method reference ตรงๆ
                              onNeedWatchIntro: () =>
                                  showWatchIntroDialog(context, _scrollToVideo),
                              onJumpToCurrent: _scrollToCurrentStep,
                              onTapLocked: (s) {
                                setState(() => _showInlineHint.add(s));
                                _scrollToCurrentStep();
                              },
                            ),
                          ),
                        ),

                        // ── Section label ─────────────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: kSurfaceCream,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.format_list_numbered_rounded,
                                    size: 15,
                                    color: kCancelColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'ขั้นตอนการฝึก',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: kDarkBrown,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: kFieldCream,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$finished / $total',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: kDarkBrown,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ── Step List ─────────────────────────────────────
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) {
                              final item = steps[i];
                              return Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    16, 0, 16, 12),
                                child: StepCard(
                                  key: _stepKeys[i],
                                  item: item,
                                  isCompleted:
                                      _completed.contains(item.index1Based),
                                  isCurrent:
                                      _currentStep == item.index1Based,
                                  showInlineHint: _showInlineHint
                                      .contains(item.index1Based),
                                  saving: _saving,
                                  onStart: () {
                                    if (!_introWatched) {
                                      // ✅ ส่ง _scrollToVideo ตรงๆ
                                      showWatchIntroDialog(
                                          context, _scrollToVideo);
                                      return;
                                    }
                                    if (item.index1Based != _currentStep) {
                                      setState(() => _showInlineHint
                                          .add(item.index1Based));
                                      _scrollToCurrentStep();
                                    }
                                  },
                                  onDone: () {
                                    if (!_introWatched) {
                                      showWatchIntroDialog(
                                          context, _scrollToVideo);
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

                        // ── Complete Banner ───────────────────────────────
                        if (isAllDone)
                          SliverToBoxAdapter(
                            child: _CompleteBanner(
                              onFinish: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                        '🎉 เยี่ยมมาก! จบบทเรียนนี้แล้ว'),
                                    backgroundColor: kSuccessGreen,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                                Future.delayed(
                                    const Duration(milliseconds: 900), () {
                                  Navigator.pushNamedAndRemoveUntil(
                                      context,
                                      AppRoutes.myCourses,
                                      (route) => route.isFirst);
                                });
                              },
                            ),
                          ),

                        const SliverToBoxAdapter(
                            child: SizedBox(height: 40)),
                      ],
                    ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: kBgColor,
      body: Center(
        child: CircularProgressIndicator(
            color: kPrimaryBrown, strokeWidth: 2.5),
      ),
    );
  }
}

// ─── Circle Icon Button ───────────────────────────────────────────────────────
class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kSurfaceCream,
          shape: BoxShape.circle,
          border: Border.all(color: kLightPaw),
        ),
        child: Icon(icon, size: 16, color: kDarkBrown),
      ),
    );
  }
}

// ─── Progress Section ─────────────────────────────────────────────────────────
class _ProgressSection extends StatelessWidget {
  final double progress;
  final int finished;
  final int total;
  const _ProgressSection(
      {required this.progress,
      required this.finished,
      required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = (progress * 100).toStringAsFixed(0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ความคืบหน้า $pct%',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kPrimaryBrown)),
              Text('$finished / $total ขั้นตอน',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: kPrimaryBrown)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: kFieldCream,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(kPrimaryBrown),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Video Thumbnail ──────────────────────────────────────────────────────────
class _VideoThumbnail extends StatelessWidget {
  final String videoId;
  final bool introWatched;
  final VoidCallback onTap;

  // ✅ super.key เพื่อให้ _videoKey ใช้ได้
  const _VideoThumbnail({
    super.key,
    required this.videoId,
    required this.introWatched,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          videoId.isNotEmpty
              ? Image.network(
                  'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 220,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
          Positioned(
            bottom: 0, left: 0, right: 0, height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    kDarkBrown.withOpacity(0.5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.92),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: kDarkBrown.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Icon(Icons.play_arrow_rounded,
                size: 36, color: Colors.red.shade600),
          ),
          if (!introWatched)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: kCancelColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text('ดูวิดีโอก่อนเริ่ม',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
        width: double.infinity,
        height: 220,
        color: kSurfaceCream,
        child: const Center(
          child: Icon(Icons.play_circle_outline_rounded,
              size: 56, color: kPrimaryBrown),
        ),
      );
}

// ─── Complete Banner ──────────────────────────────────────────────────────────
class _CompleteBanner extends StatelessWidget {
  final VoidCallback onFinish;
  const _CompleteBanner({required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF6EE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC3E6CB)),
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          const Text('ผ่านบทเรียนนี้แล้ว!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D6A3F))),
          const SizedBox(height: 4),
          const Text('น้องหมาของคุณก้าวหน้าไปอีกขั้น 🐾',
              style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4C9A5C),
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: kSuccessGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              child: const Text('สิ้นสุดบทเรียน →'),
            ),
          ),
        ],
      ),
    );
  }
}