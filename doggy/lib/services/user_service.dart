import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  // ฟังก์ชันสำหรับการลงทะเบียน
  Future<void> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // สร้างผู้ใช้ใน Firebase Authentication
      final auth.UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // บันทึกข้อมูลผู้ใช้ใน Firestore
      final User user = User(
        id: userCredential.user!.uid,
        name: name,
        email: email,
        profilePicture: null, // ค่าเริ่มต้น
      );

      await _firestore.collection('users').doc(user.id).set(user.toJson());
    } catch (e) {
      throw Exception('Error during registration: $e');
    }
  }

  // ฟังก์ชันสำหรับเข้าสู่ระบบ
  Future<User> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // เข้าสู่ระบบใน Firebase Authentication
      final auth.UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ดึงข้อมูลผู้ใช้จาก Firestore
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userCredential.user!.uid).get();

      if (userDoc.exists) {
        return User.fromJson(userDoc.data() as Map<String, dynamic>);
      } else {
        throw Exception('User not found in Firestore');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
    }
  }

  // ฟังก์ชันสำหรับออกจากระบบ
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ฟังก์ชันสำหรับดึงข้อมูลผู้ใช้ที่ล็อกอินอยู่
  Future<User?> getCurrentUser() async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        return User.fromJson(userDoc.data() as Map<String, dynamic>);
      }
    }
    return null;
  }
}
