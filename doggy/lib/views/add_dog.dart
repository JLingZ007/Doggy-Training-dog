import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dog_form.dart'; // ใช้ AppColors + DogForm

class AddDogPage extends StatefulWidget {
  const AddDogPage({super.key});

  @override
  State<AddDogPage> createState() => _AddDogPageState();
}

class _AddDogPageState extends State<AddDogPage> {
  final _formKey = GlobalKey<DogFormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _saving = false;

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null) return;

    FocusScope.of(context).unfocus();
    if (!form.validate()) return;

    setState(() => _saving = true);
    try {
      final data = form.getData();
      final user = _auth.currentUser;
      if (user == null) {
        _showSnack('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่');
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .add({
        'name': data.name,
        'age': data.age, // เก็บเป็น int
        'gender': data.gender,
        'breed': data.breed,
        'image': data.base64Image ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('สำเร็จ'),
          content: const Text('บันทึกข้อมูลสุนัขเรียบร้อยแล้ว'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ตกลง'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      title: const Text('เพิ่มข้อมูลสุนัข'),
      centerTitle: true,
      elevation: 0,
      backgroundColor: AppColors.primary, // น้ำตาลหลัก
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _appBar(),
      backgroundColor: AppColors.surface, // ครีมอ่อน
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Card(
              color: AppColors.card, // ขาว
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: AppColors.border),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: DogForm(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'บันทึกข้อมูล',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
