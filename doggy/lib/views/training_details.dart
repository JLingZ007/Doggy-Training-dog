import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class TrainingDetailsPage extends StatefulWidget {
  final String documentId;
  final String categoryId;

  const TrainingDetailsPage({
    required this.documentId,
    required this.categoryId,
    super.key,
  });

  @override
  State<TrainingDetailsPage> createState() => _TrainingDetailsPageState();
}

class _TrainingDetailsPageState extends State<TrainingDetailsPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  YoutubePlayerController? _yt;
  bool _isLoading = true;
  Map<String, dynamic>? lesson;

  // progress
  User? _user;
  int _currentStep = 1; // เริ่มนับจาก 1
  Set<int> _completed = {};

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    _init();
  }

  @override
  void dispose() {
    _yt?.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _fetchLesson();
    if (_user != null) {
      await _loadProgress();
    }
    setState(() => _isLoading = false);
  }

  String _extractYoutubeId(String url) {
    if (url.isEmpty) return '';
    if (url.contains('watch?v=')) {
      return url.split('watch?v=').last.split('&').first;
    } else if (url.contains('youtu.be/')) {
      return url.split('youtu.be/').last.split('?').first;
    } else if (url.contains('embed/')) {
      return url.split('embed/').last.split('?').first;
    }
    return '';
  }

  Future<void> _fetchLesson() async {
    final doc = await _firestore
        .collection('training_categories')
        .doc(widget.categoryId)
        .collection('programs')
        .doc(widget.documentId)
        .get();

    if (!doc.exists) {
      setState(() => _isLoading = false);
      return;
    }

    final data = doc.data() as Map<String, dynamic>;
    final id = _extractYoutubeId(data['video'] ?? '');

    if (id.isNotEmpty) {
      _yt = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
        ),
      );
    }

    setState(() => lesson = data);
  }

  Future<void> _loadProgress() async {
    if (_user == null) return;
    final ref = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('progress')
        .doc(widget.documentId);

    final snap = await ref.get();
    if (snap.exists) {
      final d = snap.data() as Map<String, dynamic>;
      _currentStep = (d['currentStep'] ?? 1) is int
          ? d['currentStep']
          : int.tryParse('${d['currentStep']}') ?? 1;
      final list = (d['completedSteps'] as List?) ?? [];
      _completed =
          list.map((e) => (e is int) ? e : int.tryParse('$e') ?? 0).toSet();
    } else {
      // เริ่มต้นเก็บ progress (เผื่อหน้า MyCourses ต้องการเวลาเริ่ม)
      await ref.set({
        'currentStep': 1,
        'completedSteps': [],
        'totalSteps': (lesson?['step'] as List?)?.length ?? 0,
        'progressPercent': 0,
        'name': lesson?['name'] ?? '',
        'image': lesson?['image'] ?? '',
        'categoryId': widget.categoryId,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _currentStep = 1;
      _completed = {};
    }
    setState(() {});
  }

  Future<void> _saveProgress({
    required int stepNo,
    required int total,
  }) async {
    if (_user == null) return;

    final finished = _completed.length.clamp(0, total);
    final percent =
        (total == 0) ? 0 : ((finished / total) * 100).round().clamp(0, 100);

    final ref = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('progress')
        .doc(widget.documentId);

    final dataToSave = {
      'currentStep': _currentStep,
      'completedSteps': _completed.toList()..sort(),
      'totalSteps': total,
      'progressPercent': percent,
      'name': lesson?['name'] ?? '',
      'image': lesson?['image'] ?? '',
      'categoryId': widget.categoryId,
      'lastStepDone': stepNo,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ถ้า 100% ให้เพิ่ม completedAt ไว้ดูในประวัติ
    if (percent >= 100) {
      dataToSave['completedAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(dataToSave, SetOptions(merge: true));
  }

  Future<void> _markStepDone(int stepNo, int total) async {
    if (_user == null) return;

    // อนุญาตให้ complete ได้เมื่อเป็น "step ปัจจุบัน"
    if (stepNo != _currentStep) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาทำตามลำดับทีละขั้น')),
      );
      return;
    }

    _completed.add(stepNo);
    // ถ้ายังมี step ถัดไปให้เลื่อนไปขั้นถัดไป, ถ้าจบแล้วค้างไว้ที่ total
    _currentStep = (stepNo < total) ? stepNo + 1 : total;

    await _saveProgress(stepNo: stepNo, total: total);
    setState(() {});
  }

  // แปลง step array ที่มี key step1/step2/... ให้เป็นรายการที่อ่านง่าย
  List<_StepItem> _parseSteps(dynamic raw) {
    final List steps = (raw is List) ? raw : [];
    final result = <_StepItem>[];
    for (var i = 0; i < steps.length; i++) {
      final m = (steps[i] as Map).cast<String, dynamic>();
      final img = (m['image'] ?? '') as String;
      String text = '';
      for (final k in m.keys) {
        if (k.toLowerCase().startsWith('step')) {
          text = '${m[k]}';
          break;
        }
      }
      result.add(_StepItem(index1Based: i + 1, text: text, image: img));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final data = lesson;
    final steps = _parseSteps(data?['step']);

    final total = steps.length;
    final finished = _completed.length.clamp(0, total);
    final progress = (total == 0) ? 0.0 : finished / total;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        centerTitle: true,
        title: Text(
          data?['name'] ?? 'บทเรียนการฝึก',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (data == null)
              ? const Center(child: Text('ไม่พบบทเรียน'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อ + แถบความคืบหน้า
                      Text(
                        data['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ProgressBar(
                        progress: progress,
                        label:
                            'ความคืบหน้า ${(progress * 100).toStringAsFixed(0)}%',
                      ),
                      const SizedBox(height: 16),

                      // วิดีโอหัวบท
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _yt != null
                            ? YoutubePlayerBuilder(
                                player: YoutubePlayer(controller: _yt!),
                                builder: (_, player) => player,
                              )
                            : ((data['image'] ?? '').toString().isNotEmpty)
                                ? Image.network(
                                    data['image'],
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _grayHeader(),
                                  )
                                : _grayHeader(),
                      ),
                      const SizedBox(height: 12),

                      // แถวข้อมูลสั้น ๆ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ความยาก: ${data['difficulty'] ?? '-'}'),
                          Text('ระยะเวลา: ${data['duration'] ?? '-'} นาที'),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // คำอธิบาย
                      if ((data['description'] ?? '').toString().isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4EDE4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(data['description'] ?? ''),
                        ),

                      const SizedBox(height: 20),

                      // รายการ Step แบบการ์ด
                      for (final s in steps) ...[
                        _StepCard(
                          item: s,
                          isCompleted: _completed.contains(s.index1Based),
                          isCurrent: _currentStep == s.index1Based,
                          onDone: () => _markStepDone(s.index1Based, total),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ถ้าจบทุก step แล้ว แสดงปุ่มสรุป
                      if (total > 0 && finished == total)
                        Center(
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 12, bottom: 40),
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('เยี่ยมมาก! จบบทเรียนนี้แล้ว')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFA4D6A7),
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 36, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: const Text('สิ้นสุดบทเรียน',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                    ],
                  ),
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

/// ----------------- helpers & widgets -----------------

class _StepItem {
  final int index1Based;
  final String text;
  final String image;
  _StepItem(
      {required this.index1Based, required this.text, required this.image});
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final String label;
  const _ProgressBar({required this.progress, required this.label});

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

class _StepCard extends StatelessWidget {
  final _StepItem item;
  final bool isCompleted;
  final bool isCurrent;
  final VoidCallback onDone;

  const _StepCard({
    required this.item,
    required this.isCompleted,
    required this.isCurrent,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    String badge;
    String btnText;
    VoidCallback? onPressed;

    if (isCompleted) {
      bg = const Color(0xFFE5F6E8); // เขียวอ่อน
      badge = 'สำเร็จแล้ว 🎉';
      btnText = 'สำเร็จแล้ว';
      onPressed = null;
    } else if (isCurrent) {
      bg = const Color(0xFFFFF1DC); // ส้มอ่อน
      badge = 'กำลังฝึก ⏳';
      btnText = 'ทำสำเร็จแล้ว';
      onPressed = onDone;
    } else {
      bg = const Color(0xFFE7F2FF); // ฟ้าอ่อน
      badge = 'เริ่มฝึก ▶️';
      btnText = 'เริ่มฝึก';
      onPressed = () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'ทำทีละขั้น กรุณาไปที่ขั้นที่ ${item.index1Based} เมื่อถึงลำดับ')),
        );
      };
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
                ? Image.network(item.image,
                    height: 170, width: double.infinity, fit: BoxFit.cover)
                : Container(
                    height: 170,
                    width: double.infinity,
                    color: const Color(0xFFEFEFEF),
                    alignment: Alignment.center,
                    child:
                        const Icon(Icons.image_not_supported, size: 48),
                  ),
          ),
          const SizedBox(height: 10),
          Text('ขั้นตอนที่ ${item.index1Based}',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(item.text, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(badge,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                child: Text(btnText,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
