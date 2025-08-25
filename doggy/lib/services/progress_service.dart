import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressService {
  final FirebaseFirestore _firestore;
  ProgressService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ref ของ progress ต่อ "ตัวสุนัข"
  CollectionReference<Map<String, dynamic>> _progressCol({
    required String userId,
    required String dogId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('dogs')
        .doc(dogId)
        .collection('progress');
  }

  /// Stream รายการ progress ของสุนัขตัวที่ระบุ (ใหม่ -> เก่า)
  Stream<QuerySnapshot<Map<String, dynamic>>> streamDogProgress({
    required String userId,
    required String dogId,
  }) {
    return _progressCol(userId: userId, dogId: dogId)
        .orderBy('updatedAt', descending: true)
        .withConverter<Map<String, dynamic>>(
          fromFirestore: (snap, _) => (snap.data() ?? {}),
          toFirestore: (data, _) => data,
        )
        .snapshots();
  }

  /// รีเซ็ตคอร์ส (เริ่มใหม่) — ต่อสุนัขตัวที่ระบุ
  Future<void> resetCourse({
    required String userId,
    required String dogId,
    required String programId,
    required String categoryId,
    required int totalSteps,
    required String name,
    required String image,
  }) async {
    final ref = _progressCol(userId: userId, dogId: dogId).doc(programId);

    await ref.set({
      'currentStep': 1,
      'completedSteps': [],
      'totalSteps': totalSteps,
      'progressPercent': 0,
      'name': name,
      'image': image,
      'categoryId': categoryId,
      'startedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'lastStepDone': null,
    }, SetOptions(merge: true));
  }

  /// คำนวณสถานะจากเปอร์เซ็นต์
  bool isCompleted(int percent) => percent >= 100;

  /// ปลอดภัยต่อ null -> int
  int asInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
