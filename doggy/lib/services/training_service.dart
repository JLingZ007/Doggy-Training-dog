import 'package:cloud_firestore/cloud_firestore.dart';

class TrainingService {
  final FirebaseFirestore _firestore;
  TrainingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ดึงข้อมูลบทเรียน
  Future<Map<String, dynamic>?> fetchLesson({
    required String categoryId,
    required String documentId,
  }) async {
    final doc = await _firestore
        .collection('training_categories')
        .doc(categoryId)
        .collection('programs')
        .doc(documentId)
        .get();

    if (!doc.exists) return null;
    return doc.data() as Map<String, dynamic>?;
  }

  /// แปลง URL YouTube -> videoId
  String extractYoutubeId(String url) {
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

  /// document reference ของ progress ต่อ "ตัวสุนัข"
  DocumentReference<Map<String, dynamic>> _progressRef({
    required String userId,
    required String dogId,
    required String programId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dogs')
        .doc(dogId)
        .collection('progress')
        .doc(programId);
  }

  /// โหลด progress (ตาม dogId)
  Future<ProgressData> loadProgress({
    required String userId,
    required String dogId,
    required String documentId,
    required String categoryId,
    required Map<String, dynamic>? lesson,
  }) async {
    final ref = _progressRef(userId: userId, dogId: dogId, programId: documentId);
    final snap = await ref.get();

    final totalSteps = (lesson?['step'] as List?)?.length ?? 0;

    if (snap.exists) {
      final d = snap.data() as Map<String, dynamic>;
      final currentStep = (d['currentStep'] ?? 1) is int
          ? d['currentStep']
          : int.tryParse('${d['currentStep']}') ?? 1;
      final list = (d['completedSteps'] as List?) ?? [];
      final completed =
          list.map((e) => (e is int) ? e : int.tryParse('$e') ?? 0).toSet();

      final introWatched = (d['introWatched'] == true);
      final introWatchSec = (d['introWatchSec'] is int)
          ? d['introWatchSec'] as int
          : int.tryParse('${d['introWatchSec'] ?? 0}') ?? 0;

      return ProgressData(
        currentStep: currentStep,
        completed: completed,
        totalSteps: totalSteps > 0 ? totalSteps : (d['totalSteps'] ?? 0),
        introWatched: introWatched,
        introWatchSec: introWatchSec,
      );
    } else {
      // เริ่มต้น progress สำหรับสุนัขตัวนี้
      await ref.set({
        'currentStep': 1,
        'completedSteps': [],
        'totalSteps': totalSteps,
        'progressPercent': 0,
        'name': lesson?['name'] ?? '',
        'image': lesson?['image'] ?? '',
        'categoryId': categoryId,
        'introWatched': false,
        'introWatchSec': 0,
        'startedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return ProgressData(
        currentStep: 1,
        completed: <int>{},
        totalSteps: totalSteps,
        introWatched: false,
        introWatchSec: 0,
      );
    }
  }

  /// เซฟ progress (ตาม dogId)
  Future<void> saveProgress({
    required String userId,
    required String dogId,
    required String documentId,
    required String categoryId,
    required Map<String, dynamic>? lesson,
    required int currentStep,
    required Set<int> completed,
    required int totalSteps,
    required int lastStepDone,
  }) async {
    final finished = completed.length.clamp(0, totalSteps);
    final percent = (totalSteps == 0)
        ? 0
        : ((finished / totalSteps) * 100).round().clamp(0, 100);

    final ref = _progressRef(userId: userId, dogId: dogId, programId: documentId);

    final dataToSave = {
      'currentStep': currentStep,
      'completedSteps': completed.toList()..sort(),
      'totalSteps': totalSteps,
      'progressPercent': percent,
      'name': lesson?['name'] ?? '',
      'image': lesson?['image'] ?? '',
      'categoryId': categoryId,
      'lastStepDone': lastStepDone,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (percent >= 100) {
      dataToSave['completedAt'] = FieldValue.serverTimestamp();
    }

    await ref.set(dataToSave, SetOptions(merge: true));
  }

  /// อัปเดตสถานะการดูวิดีโอแนะนำ (อินโทร)
  Future<void> updateIntroWatch({
    required String userId,
    required String dogId,
    required String documentId,
    required bool watched, // true เมื่อดูครบตามเกณฑ์ / จบวิดีโอ
    int? watchSec,         // เก็บเวลาที่ดูล่าสุด (วินาที)
  }) async {
    final ref = _progressRef(userId: userId, dogId: dogId, programId: documentId);
    final data = <String, dynamic>{
      'introWatched': watched,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (watchSec != null) data['introWatchSec'] = watchSec;
    await ref.set(data, SetOptions(merge: true));
  }
}

class ProgressData {
  final int currentStep;
  final Set<int> completed;
  final int totalSteps;
  final bool introWatched;
  final int introWatchSec;

  ProgressData({
    required this.currentStep,
    required this.completed,
    required this.totalSteps,
    required this.introWatched,
    required this.introWatchSec,
  });
}
