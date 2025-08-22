import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // ---------- Auth ----------
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User user = User(
        id: cred.user!.uid,
        name: name,
        email: email,
        profilePicture: null,
      );

      await _firestore.collection('users').doc(user.id).set({
        ...user.toJson(),
        'activeDogId': null, // ยังไม่เลือกสุนัขตัวหลัก
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(cred.user!.uid).get();
      if (!doc.exists) {
        throw Exception('User not found in Firestore');
      }
      return User.fromJson(doc.data() as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<User?> getCurrentUser() async {
    final current = _auth.currentUser;
    if (current == null) return null;
    final doc = await _firestore.collection('users').doc(current.uid).get();
    if (!doc.exists) return null;
    return User.fromJson(doc.data() as Map<String, dynamic>);
  }

  auth.User? get authUser => _auth.currentUser;

  // ---------- Active Dog (สลับโปรไฟล์สุนัข) ----------
  Future<void> setActiveDogId(String dogId) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');
    await _firestore.collection('users').doc(u.uid).set({
      'activeDogId': dogId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// สลับ active dog พร้อมตรวจสอบว่า dogId เป็นของผู้ใช้จริง
  Future<bool> switchActiveDog(String dogId) async {
    final u = _auth.currentUser;
    if (u == null) throw Exception('Not logged in');

    final dogRef = _firestore
        .collection('users')
        .doc(u.uid)
        .collection('dogs')
        .doc(dogId);

    final dogSnap = await dogRef.get();
    if (!dogSnap.exists) {
      throw Exception('Dog not found for this user');
    }

    await _firestore.collection('users').doc(u.uid).set(
      {
        'activeDogId': dogId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return true;
  }

  /// หากยังไม่มี activeDogId จะเลือก "ตัวแรก" ให้อัตโนมัติและคืนค่า id
  Future<String?> getOrSetDefaultActiveDog() async {
    final u = _auth.currentUser;
    if (u == null) return null;

    final userDoc = await _firestore.collection('users').doc(u.uid).get();
    final currentActive = userDoc.data()?['activeDogId'] as String?;
    if (currentActive != null && currentActive.isNotEmpty) return currentActive;

    final dogs = await _firestore
        .collection('users')
        .doc(u.uid)
        .collection('dogs')
        .orderBy('name')
        .limit(1)
        .get();

    if (dogs.docs.isEmpty) return null;

    final firstId = dogs.docs.first.id;
    await _firestore.collection('users').doc(u.uid).set(
      {
        'activeDogId': firstId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    return firstId;
  }

  Future<void> clearActiveDogIfDeleted(String dogId) async {
    final u = _auth.currentUser;
    if (u == null) return;
    final userRef = _firestore.collection('users').doc(u.uid);
    final snap = await userRef.get();
    final activeDogId = snap.data()?['activeDogId'];
    if (activeDogId == dogId) {
      await userRef.set({'activeDogId': null}, SetOptions(merge: true));
    }
  }

  Future<String?> getActiveDogId() async {
    final u = _auth.currentUser;
    if (u == null) return null;
    final doc = await _firestore.collection('users').doc(u.uid).get();
    return doc.data()?['activeDogId'] as String?;
  }

  Stream<String?> activeDogIdStream() {
    final u = _auth.currentUser;
    if (u == null) return const Stream.empty();
    return _firestore.collection('users').doc(u.uid).snapshots().map(
          (s) => (s.data()?['activeDogId'] as String?),
        );
  }

  /// ดึงข้อมูลสุนัขที่ active ปัจจุบัน (อาจเป็น null)
  Future<Map<String, dynamic>?> getActiveDogData() async {
    final u = _auth.currentUser;
    if (u == null) return null;

    final activeId = await getActiveDogId();
    if (activeId == null) return null;

    final snap = await _firestore
        .collection('users')
        .doc(u.uid)
        .collection('dogs')
        .doc(activeId)
        .get();

    return snap.data();
  }

  /// รายการสุนัขแบบย่อ (id/name/image) ใช้โชว์ในแผ่นเลือกโปรไฟล์
  Future<List<Map<String, String>>> listDogsSummary() async {
    final u = _auth.currentUser;
    if (u == null) return [];

    final qs = await _firestore
        .collection('users')
        .doc(u.uid)
        .collection('dogs')
        .orderBy('name')
        .get();

    return qs.docs.map((d) {
      final m = (d.data()) as Map<String, dynamic>;
      return {
        'id': d.id,
        'name': (m['name'] ?? 'ไม่ระบุ').toString(),
        'image': (m['image'] ?? '').toString(),
      };
    }).toList();
  }

  // ---------- Path helpers: progress ต่อ “ตัวสุนัข” ----------
  /// users/{uid}/dogs/{dogId}/progress/{programId}
  DocumentReference<Map<String, dynamic>> progressDocRef({
    required String dogId,
    required String programId,
  }) {
    final u = _auth.currentUser;
    if (u == null) {
      throw Exception('Not logged in');
    }
    return _firestore
        .collection('users')
        .doc(u.uid)
        .collection('dogs')
        .doc(dogId)
        .collection('progress')
        .doc(programId);
  }
}
