import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// สีถูกย้ายมารวมในไฟล์นี้
class AppColors {
  static const Color primary = Color(0xFFD2B48C); // Tan
  static const Color surface = Color(0xFFF7F3EF);
  static const Color card = Colors.white;
  static const Color text = Color(0xFF4A3C31);
  static const Color subtext = Color(0xFF7D6E65);
  static const Color border = Color(0xFFE5DED8);
  static const Color accent = Color(0xFF6D9C6D);
}

// Data class สำหรับเก็บข้อมูลจากฟอร์ม
class DogFormData {
  final String name;
  final int age;
  final String gender;
  final String breed;
  final String? base64Image;

  DogFormData({
    required this.name,
    required this.age,
    required this.gender,
    required this.breed,
    this.base64Image,
  });
}

class DogForm extends StatefulWidget {
  // เพิ่ม initial values สำหรับการแก้ไขข้อมูล
  final String? initialName;
  final int? initialAge;
  final String? initialGender;
  final String? initialBreed;
  final String? initialBase64Image;

  const DogForm({
    super.key,
    this.initialName,
    this.initialAge,
    this.initialGender,
    this.initialBreed,
    this.initialBase64Image,
  });

  @override
  // ทำให้ State เป็น public เพื่อให้ page ภายนอกเข้าถึงได้
  DogFormState createState() => DogFormState();
}

class DogFormState extends State<DogForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _customBreedCtrl = TextEditingController();

  int? _age;
  String? _gender;
  String? _breed;
  String? _base64Image;
  bool _showImageLoading = false;
  bool _showCustomBreedField = false;

  final _picker = ImagePicker();

  final List<int> _ages = List.generate(20, (i) => i + 1); // อายุ 1-20 ปี
  final List<String> _genders = const ['เพศผู้', 'เพศเมีย'];
  // รายการสายพันธุ์สุนัขที่นิยมในไทย (จากเวอร์ชันก่อนหน้า)
  final List<String> _dogBreeds = const [
    'ไทยบางแก้ว', 'ไทยหลังอาน', 'ปอมเมอเรเนียน', 'ชิวาวา', 'ไซบีเรียน ฮัสกี้',
    'โกลเด้น รีทรีฟเวอร์', 'พุดเดิ้ล', 'ชิสุ', 'บีเกิ้ล', 'คอร์กี้',
    'เฟรนช์ บูลด็อก', 'ปั๊ก', 'เยอรมันเชพเพิร์ด', 'ลาบราดอร์ รีทรีฟเวอร์',
    'แจ็ค รัสเซลล์ เทอร์เรีย', 'ยอร์คเชียร์ เทอร์เรีย', 'มอลทีส', 'ซามอยด์',
    'พันธุ์ผสม / พันทาง', 'อื่นๆ (ระบุเอง)',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName ?? '';
    _age = widget.initialAge ?? 1;
    _gender = _genders.contains(widget.initialGender) ? widget.initialGender : null;
    _base64Image = (widget.initialBase64Image ?? '').isNotEmpty ? widget.initialBase64Image : null;

    // ตั้งค่าสายพันธุ์เริ่มต้น
    if (widget.initialBreed != null) {
      if (_dogBreeds.contains(widget.initialBreed)) {
        _breed = widget.initialBreed;
        if (_breed == 'อื่นๆ (ระบุเอง)') {
          _showCustomBreedField = true;
          // ในกรณีแก้ไข ควรมีค่า custom breed มาด้วย แต่โค้ดนี้ไม่ได้ส่งมา
        }
      } else {
        // ถ้าสายพันธุ์ที่เคยบันทึกไว้ไม่อยู่ใน list ให้ตั้งเป็น "อื่นๆ"
        _breed = 'อื่นๆ (ระบุเอง)';
        _showCustomBreedField = true;
        _customBreedCtrl.text = widget.initialBreed!;
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _customBreedCtrl.dispose();
    super.dispose();
  }

  // --- Public methods ---
  bool validate() => _formKey.currentState?.validate() ?? false;

  DogFormData getData() {
    final breedValue = _showCustomBreedField ? _customBreedCtrl.text.trim() : _breed;
    return DogFormData(
      name: _nameCtrl.text.trim(),
      age: _age ?? 1,
      gender: _gender ?? '',
      breed: breedValue ?? '',
      base64Image: _base64Image,
    );
  }
  // --------------------

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _showImageLoading = true);
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80, maxWidth: 800);
      if (picked != null) {
        final bytes = await File(picked.path).readAsBytes();
        setState(() => _base64Image = base64Encode(bytes));
      }
    } finally {
      if (mounted) setState(() => _showImageLoading = false);
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('ถ่ายรูปด้วยกล้อง'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('เลือกรูปจากแกลเลอรี'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_base64Image != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('ลบรูปภาพ'),
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _base64Image = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    );
  }

  Widget _imagePreview() {
    Widget avatarChild;
    if (_showImageLoading) {
      avatarChild = const Center(child: CircularProgressIndicator());
    } else if (_base64Image != null && _base64Image!.isNotEmpty) {
      avatarChild = ClipRRect(
        borderRadius: BorderRadius.circular(64),
        child: Image.memory(
          base64Decode(_base64Image!),
          width: 128,
          height: 128,
          fit: BoxFit.cover,
        ),
      );
    } else {
      avatarChild = const Icon(Icons.pets, size: 56, color: AppColors.subtext);
    }

    return Stack(
      children: [
        Container(
          width: 128,
          height: 128,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: avatarChild,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _showImagePickerSheet,
              child: const Padding(
                padding: EdgeInsets.all(10),
                child: Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.text,
          fontWeight: FontWeight.w600,
        );

    return Form(
      key: _formKey,
      child: Column(
        children: [
          const SizedBox(height: 8),
          _imagePreview(),
          const SizedBox(height: 20),

          // ชื่อ
          Align(alignment: Alignment.centerLeft, child: Text('ชื่อสุนัข', style: labelStyle)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            decoration: _decoration('ชื่อสุนัข', hint: 'เช่น โบโบ้'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อสุนัข' : null,
          ),
          const SizedBox(height: 16),

          // อายุ
          Align(alignment: Alignment.centerLeft, child: Text('อายุ', style: labelStyle)),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _age,
            isExpanded: true,
            items: _ages
                .map((y) => DropdownMenuItem(value: y, child: Text('$y ปี')))
                .toList(),
            onChanged: (v) => setState(() => _age = v),
            decoration: _decoration('อายุ'),
          ),
          const SizedBox(height: 16),

          // เพศ
          Align(alignment: Alignment.centerLeft, child: Text('เพศ', style: labelStyle)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _gender,
            isExpanded: true,
            items: _genders
                .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                .toList(),
            onChanged: (v) => setState(() => _gender = v),
            decoration: _decoration('เพศ'),
            validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกเพศ' : null,
          ),
          const SizedBox(height: 16),

          // สายพันธุ์
          Align(alignment: Alignment.centerLeft, child: Text('สายพันธุ์', style: labelStyle)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _breed,
            isExpanded: true,
            items: _dogBreeds
                .map((b) => DropdownMenuItem(value: b, child: Text(b, overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) {
              setState(() {
                _breed = v;
                _showCustomBreedField = (v == 'อื่นๆ (ระบุเอง)');
                if (!_showCustomBreedField) {
                  _customBreedCtrl.clear();
                }
              });
            },
            decoration: _decoration('สายพันธุ์'),
            validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกสายพันธุ์' : null,
          ),
          const SizedBox(height: 8),

          // ช่องกรอกสายพันธุ์เอง
          if (_showCustomBreedField) ...[
            const SizedBox(height: 8),
            TextFormField(
              controller: _customBreedCtrl,
              decoration: _decoration('ระบุสายพันธุ์'),
              validator: (v) {
                if (_showCustomBreedField && (v == null || v.trim().isEmpty)) {
                  return 'กรุณาระบุสายพันธุ์';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
