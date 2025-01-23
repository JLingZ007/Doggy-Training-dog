import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/training_program.dart';

class TrainingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ดึงโปรแกรมการฝึกทั้งหมด
  Future<List<TrainingProgram>> fetchTrainingPrograms() async {
    try {
      final snapshot = await _firestore.collection('training_programs').get();

      return snapshot.docs
          .map((doc) => TrainingProgram.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch training programs: $e');
    }
  }

  // เพิ่มโปรแกรมการฝึกใหม่
  Future<void> addTrainingProgram(TrainingProgram program) async {
    try {
      await _firestore
          .collection('training_programs')
          .add(program.toJson());
    } catch (e) {
      throw Exception('Failed to add training program: $e');
    }
  }

  // ลบโปรแกรมการฝึก
  Future<void> deleteTrainingProgram(String programId) async {
    try {
      await _firestore.collection('training_programs').doc(programId).delete();
    } catch (e) {
      throw Exception('Failed to delete training program: $e');
    }
  }
}
