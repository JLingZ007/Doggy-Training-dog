// home_service.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeService {
  final FirebaseFirestore _firestore;
  HomeService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ใช้ cache ก่อน ถ้าไม่มีค่อยไปเน็ต (stale-while-revalidate)
  Future<QuerySnapshot<Map<String, dynamic>>?> _getCached(
      Query<Map<String, dynamic>> q) async {
    try {
      final s = await q.get(const GetOptions(source: Source.cache));
      if (s.docs.isNotEmpty) return s;
    } catch (_) {}
    return null;
  }

  /// ดึงรูปโปรไฟล์น้องหมาตัวแรก (อย่างมาก 1 doc)
  Future<String?> fetchDogProfileImage(String userId) async {
    final base = _firestore
        .collection('users')
        .doc(userId)
        .collection('dogs')
        .limit(1);

    // ลอง cache ก่อน
    final cached = await _getCached(base);
    if (cached != null && cached.docs.isNotEmpty) {
      final d = cached.docs.first.data();
      final img = d['image']?.toString();
      if (img != null && img.isNotEmpty) return img;
    }

    // จากเน็ต (เงียบๆ)
    final snap = await base.get();
    if (snap.docs.isEmpty) return null;
    final d = snap.docs.first.data();
    final img = d['image']?.toString();
    return (img == null || img.isEmpty) ? null : img;
  }

  /// คอร์สที่ผู้ใช้ “เรียนต่อ” (ยังไม่จบและอัปเดตล่าสุด)
  Future<Map<String, dynamic>?> fetchContinueCourse(String userId) async {
    final base = _firestore
        .collection('users')
        .doc(userId)
        .collection('progress')
        .orderBy('updatedAt', descending: true)
        .limit(10);

    // cache ก่อน
    final cached = await _getCached(base);
    Map<String, dynamic>? pickFrom(QuerySnapshot<Map<String, dynamic>> s) {
      for (final d in s.docs) {
        final data = d.data();
        final percent = _asInt(data['progressPercent']);
        if (percent < 100) {
          return {
            'programId': d.id,
            'categoryId': data['categoryId'] ?? '',
            'name': data['name'] ?? '',
            'image': data['image'] ?? '',
            'percent': percent,
            'currentStep': _asInt(data['currentStep'], 1),
            'totalSteps': _asInt(data['totalSteps']),
          };
        }
      }
      return null;
    }

    if (cached != null) {
      final p = pickFrom(cached);
      if (p != null) return p;
    }

    final snap = await base.get();
    return pickFrom(snap);
  }

  /// โปรแกรมแนะนำแบบเร็ว (หลีกเลี่ยง collectionGroup ขนาดใหญ่)
  /// ใช้ collectionGroup แต่จำกัด .limit(8) เพื่อความเร็ว
  Future<List<Map<String, dynamic>>> fetchFeaturedQuick({int limit = 8}) async {
    final base = _firestore.collectionGroup('programs').limit(limit);

    // cache ก่อน
    final cached = await _getCached(base);
    List<Map<String, dynamic>> convert(QuerySnapshot<Map<String, dynamic>> s) {
      final all = s.docs.map((doc) {
        final data = doc.data();
        final parentCat = doc.reference.parent.parent;
        return {
          'documentId': doc.id,
          'categoryId': parentCat?.id ?? '',
          'name': data['name'] ?? '',
          'image': data['image'] ?? '',
          'difficulty': data['difficulty'] ?? '',
          'duration': data['duration'] ?? '',
        };
      }).toList();
      // สลับเล็กน้อยให้ดูหลากหลาย
      all.shuffle(Random());
      return all;
    }

    if (cached != null) {
      final list = convert(cached);
      if (list.isNotEmpty) return list;
    }

    final snap = await base.get();
    return convert(snap);
  }

  /// หมวดหมู่: ดึงน้อยลง (default 6)
  Future<List<Map<String, dynamic>>> fetchCategoriesFast({int limit = 6}) async {
    final base = _firestore.collection('training_categories').limit(limit);

    // cache ก่อน
    final cached = await _getCached(base);
    List<Map<String, dynamic>> convert(QuerySnapshot<Map<String, dynamic>> s) {
      return s.docs.map((d) {
        final m = d.data();
        return {
          'categoryId': d.id,
          'name': m['name'] ?? '',
          'image': m['image'] ?? '',
        };
      }).toList();
    }

    if (cached != null) {
      final list = convert(cached);
      if (list.isNotEmpty) return list;
    }

    final snap = await base.get();
    return convert(snap);
  }

  static int _asInt(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }
}
