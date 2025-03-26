import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dog.dart';

class DogRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงข้อมูลสุนัขทั้งหมดสำหรับผู้ใช้คนหนึ่ง
  Future<List<Dog>> fetchDogs(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('dogs')
          .get();

      return snapshot.docs.map((doc) => Dog.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch dogs: $e');
    }
  }

  // เพิ่มสุนัขใหม่
  Future<void> addDog(String userId, Dog dog) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dogs')
          .add(dog.toJson());
    } catch (e) {
      throw Exception('Failed to add dog: $e');
    }
  }

  // ลบข้อมูลสุนัข
  Future<void> deleteDog(String userId, String dogId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('dogs')
          .doc(dogId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete dog: $e');
    }
  }
}
