import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

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
  // String extractYoutubeId(String url) {
  //   if (url.isEmpty) return '';
  //   if (url.contains('watch?v=')) {
  //     return url.split('watch?v=').last.split('&').first;
  //   } else if (url.contains('youtu.be/')) {
  //     return url.split('youtu.be/').last.split('?').first;
  //   } else if (url.contains('embed/')) {
  //     return url.split('embed/').last.split('?').first;
  //   }
  //   return '';
  // }

  String extractYoutubeId(String url) {
    if (url.isEmpty) return '';

    try {
      // ลบช่องว่างและ trim
      url = url.trim();

      // ถ้าเป็น Video ID อยู่แล้ว (11 ตัวอักษร)
      if (url.length == 11 && !url.contains('/') && !url.contains('?')) {
        return url;
      }

      // รูปแบบต่างๆ ของ YouTube URL
      final patterns = [
        // Standard watch URL: https://www.youtube.com/watch?v=VIDEO_ID
        RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})'),
        
        // Short URL: https://youtu.be/VIDEO_ID
        RegExp(r'(?:youtu\.be\/)([a-zA-Z0-9_-]{11})'),
        
        // Embed URL: https://www.youtube.com/embed/VIDEO_ID
        RegExp(r'(?:youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
        
        // Mobile URL: https://m.youtube.com/watch?v=VIDEO_ID
        RegExp(r'(?:m\.youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})'),
        
        // URL with timestamp: https://www.youtube.com/watch?v=VIDEO_ID&t=123s
        RegExp(r'(?:youtube\.com\/watch\?v=)([a-zA-Z0-9_-]{11})(?:&|$)'),
        
        // User URL: https://www.youtube.com/user/.../watch?v=VIDEO_ID
        RegExp(r'(?:youtube\.com\/(?:user\/)?.*\/watch\?v=)([a-zA-Z0-9_-]{11})'),
        
        // General pattern (fallback)
        RegExp(r'(?:v=|\/v\/|youtu\.be\/|\/embed\/)([a-zA-Z0-9_-]{11})'),
      ];

      // ลองจับคู่กับแต่ละ pattern
      for (final pattern in patterns) {
        final match = pattern.firstMatch(url);
        if (match != null && match.group(1) != null) {
          final videoId = match.group(1)!;
          
          // ตรวจสอบว่าเป็น Video ID ที่ถูกต้อง (11 ตัวอักษร)
          if (videoId.length == 11) {
            print('✅ YouTube Video ID extracted: $videoId');
            return videoId;
          }
        }
      }

      print('❌ Could not extract YouTube Video ID from: $url');
      return '';
      
    } catch (e) {
      print('❌ Error extracting YouTube ID: $e');
      return '';
    }
  }

// ฟังก์ชันเสริม: ตรวจสอบว่า Video ID ถูกต้องหรือไม่
  bool isValidYoutubeId(String id) {
    if (id.isEmpty || id.length != 11) return false;
    
    // ตรวจสอบว่ามีเฉพาะตัวอักษรที่ YouTube ใช้
    final validPattern = RegExp(r'^[a-zA-Z0-9_-]{11}$');
    return validPattern.hasMatch(id);
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
