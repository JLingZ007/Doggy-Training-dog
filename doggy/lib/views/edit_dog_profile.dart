import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widgets/dog_form.dart';

class EditDogProfilePage extends StatefulWidget {
  final Map<String, dynamic> dogData;
  final String docId;

  const EditDogProfilePage({
    super.key,
    required this.dogData,
    required this.docId,
  });

  @override
  State<EditDogProfilePage> createState() => _EditDogProfilePageState();
}

class _EditDogProfilePageState extends State<EditDogProfilePage> {
  final _formKey   = GlobalKey<DogFormState>();
  final _auth      = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _saving = false;

  // ── Save ───────────────────────────────────────────────────────────────────
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
        _showSnack('ไม่พบผู้ใช้ กรุณาเข้าสู่ระบบใหม่', isError: true);
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .doc(widget.docId)
          .update({
        'name':      data.name,
        'age':       data.age,
        'gender':    data.gender,
        'breed':     data.breed,
        'image':     data.base64Image ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // ── Success dialog ───────────────────────────────────────────────────
      await showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.35),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.fieldBorder),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF6EE),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFC3E6CB)),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 28, color: Color(0xFF4C9A5C)),
                ),
                const SizedBox(height: 14),
                const Text(
                  'บันทึกสำเร็จ!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ข้อมูลสุนัขของคุณถูกอัปเดตแล้ว 🐾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.primary,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.darkBrown,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                      textStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    child: const Text('เสร็จสิ้น'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnack('เกิดข้อผิดพลาด: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            isError ? AppColors.cancelRed : AppColors.darkBrown,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static int _parseAge(dynamic raw) {
    if (raw == null) return 1;
    if (raw is int) return raw;
    final n = int.tryParse(raw.toString().replaceAll(RegExp(r'[^0-9]'), ''));
    return (n == null || n < 1) ? 1 : n.clamp(1, 20);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.dogData;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 56,
        leadingWidth: 56,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.fieldBorder),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 15, color: AppColors.darkBrown),
            ),
          ),
        ),
        title: const Text(
          'แก้ไขข้อมูลสุนัข',
          style: TextStyle(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: Column(
        children: [

          // ── Form ─────────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [

                // Dog name chip (ชื่อที่กำลังแก้)
                if ((d['name'] ?? '').toString().isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 16, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'กำลังแก้ไขข้อมูล',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                d['name'].toString(),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.fieldBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(18),
                  child: DogForm(
                    key: _formKey,
                    initialName: (d['name'] ?? '') as String,
                    initialAge: (d['age'] is int)
                        ? d['age'] as int
                        : _parseAge(d['age']),
                    initialGender: (d['gender'] ?? '') as String,
                    initialBreed: (d['breed'] ?? '') as String,
                    initialBase64Image: (d['image'] ?? '') as String,
                  ),
                ),
              ],
            ),
          ),

          // ── Save button (pinned bottom) ───────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                  top: BorderSide(color: AppColors.fieldBorder)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBrown,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.fieldBorder,
                  disabledForegroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.primary,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('บันทึกการแก้ไข'),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}