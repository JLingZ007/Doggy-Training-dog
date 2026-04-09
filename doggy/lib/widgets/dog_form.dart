import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ─── AppColors ────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary  = Color(0xFFD2B48C); // Tan
  static const Color surface  = Color(0xFFF7F3EF);
  static const Color card     = Colors.white;
  static const Color text     = Color(0xFF4A3C31);
  static const Color subtext  = Color(0xFF7D6E65);
  static const Color border   = Color(0xFFE5DED8);
  static const Color accent   = Color(0xFF6D9C6D);

  // เพิ่มเติมสำหรับ form
  static const Color fieldBg  = Color(0xFFEAD8C8);
  static const Color fieldBorder = Color(0xFFE8D5C0);
  static const Color darkBrown   = Color(0xFF6D4C41);
  static const Color cancelRed   = Color(0xFF7C5959);
}

// ─── Data class ───────────────────────────────────────────────────────────────
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

// ─── DogForm ──────────────────────────────────────────────────────────────────
class DogForm extends StatefulWidget {
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
  DogFormState createState() => DogFormState();
}

class DogFormState extends State<DogForm> {
  final _formKey         = GlobalKey<FormState>();
  final _nameCtrl        = TextEditingController();
  final _customBreedCtrl = TextEditingController();

  int?    _age;
  String? _gender;
  String? _breed;
  String? _base64Image;
  bool    _showImageLoading     = false;
  bool    _showCustomBreedField = false;

  final _picker = ImagePicker();

  final _ages    = List.generate(20, (i) => i + 1);
  final _genders = const ['เพศผู้', 'เพศเมีย'];
  final _dogBreeds = const [
    'ไทยบางแก้ว', 'ไทยหลังอาน', 'ปอมเมอเรเนียน', 'ชิวาวา',
    'ไซบีเรียน ฮัสกี้', 'โกลเด้น รีทรีฟเวอร์', 'พุดเดิ้ล', 'ชิสุ',
    'บีเกิ้ล', 'คอร์กี้', 'เฟรนช์ บูลด็อก', 'ปั๊ก',
    'เยอรมันเชพเพิร์ด', 'ลาบราดอร์ รีทรีฟเวอร์',
    'แจ็ค รัสเซลล์ เทอร์เรีย', 'ยอร์คเชียร์ เทอร์เรีย',
    'มอลทีส', 'ซามอยด์', 'พันธุ์ผสม / พันทาง', 'อื่นๆ (ระบุเอง)',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.initialName ?? '';
    _age           = widget.initialAge ?? 1;
    _gender        = _genders.contains(widget.initialGender)
        ? widget.initialGender : null;
    _base64Image   = (widget.initialBase64Image ?? '').isNotEmpty
        ? widget.initialBase64Image : null;

    if (widget.initialBreed != null) {
      if (_dogBreeds.contains(widget.initialBreed)) {
        _breed = widget.initialBreed;
        if (_breed == 'อื่นๆ (ระบุเอง)') _showCustomBreedField = true;
      } else {
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

  // ── Public API ─────────────────────────────────────────────────────────────
  bool validate() => _formKey.currentState?.validate() ?? false;

  DogFormData getData() {
    final breedValue = _showCustomBreedField
        ? _customBreedCtrl.text.trim() : _breed;
    return DogFormData(
      name:        _nameCtrl.text.trim(),
      age:         _age ?? 1,
      gender:      _gender ?? '',
      breed:       breedValue ?? '',
      base64Image: _base64Image,
    );
  }

  // ── Image picker ───────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    setState(() => _showImageLoading = true);
    try {
      final picked = await _picker.pickImage(
          source: source, imageQuality: 80, maxWidth: 800);
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
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 18),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fieldBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const Text('เลือกรูปภาพสุนัข',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkBrown)),
            const SizedBox(height: 16),
            _SheetOption(
              icon: Icons.photo_camera_rounded,
              label: 'ถ่ายรูปด้วยกล้อง',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            const SizedBox(height: 8),
            _SheetOption(
              icon: Icons.photo_library_rounded,
              label: 'เลือกรูปจากแกลเลอรี',
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            if (_base64Image != null) ...[
              const SizedBox(height: 8),
              _SheetOption(
                icon: Icons.delete_outline_rounded,
                label: 'ลบรูปภาพ',
                color: AppColors.cancelRed,
                onTap: () { Navigator.pop(context); setState(() => _base64Image = null); },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Input decoration ───────────────────────────────────────────────────────
  InputDecoration _dec(String label, {String? hint, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
          color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w600),
      prefixIcon: icon != null
          ? Icon(icon, size: 18, color: AppColors.primary) : null,
      filled: true,
      fillColor: AppColors.fieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.fieldBorder)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade300)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5)),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.darkBrown,
                letterSpacing: 0.2)),
      );

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Avatar ────────────────────────────────────────────────────
          Center(
            child: Stack(
              children: [
                Container(
                  width: 110, height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.fieldBorder, width: 2),
                  ),
                  child: _showImageLoading
                      ? const Center(child: CircularProgressIndicator(
                          color: AppColors.primary, strokeWidth: 2.5))
                      : _base64Image != null
                          ? ClipOval(
                              child: Image.memory(
                                base64Decode(_base64Image!),
                                width: 110, height: 110, fit: BoxFit.cover,
                              ))
                          : const Icon(Icons.pets_rounded,
                              size: 44, color: AppColors.primary),
                ),
                Positioned(
                  bottom: 2, right: 2,
                  child: GestureDetector(
                    onTap: _showImagePickerSheet,
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.darkBrown,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('แตะเพื่อเปลี่ยนรูปภาพ',
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary.withOpacity(0.8),
                    fontWeight: FontWeight.w500)),
          ),

          const SizedBox(height: 24),

          // ── ชื่อสุนัข ─────────────────────────────────────────────────
          _label('ชื่อสุนัข'),
          TextFormField(
            controller: _nameCtrl,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
                color: AppColors.darkBrown, fontSize: 15, fontWeight: FontWeight.w600),
            decoration: _dec('ชื่อสุนัข',
                hint: 'เช่น โบโบ้, แม็กซ์',
                icon: Icons.badge_outlined),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'กรุณากรอกชื่อสุนัข' : null,
          ),

          const SizedBox(height: 16),

          // ── อายุ + เพศ ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('อายุ'),
                    DropdownButtonFormField<int>(
                      value: _age,
                      isExpanded: true,
                      menuMaxHeight: 280,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.expand_more_rounded,
                          color: AppColors.primary, size: 20),
                      items: _ages.map((y) => DropdownMenuItem(
                              value: y, child: Text('$y ปี'))).toList(),
                      onChanged: (v) => setState(() => _age = v),
                      decoration: _dec('อายุ', icon: Icons.cake_outlined),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('เพศ'),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      isExpanded: true,
                      menuMaxHeight: 200,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                          color: AppColors.darkBrown,
                          fontSize: 14,
                          fontWeight: FontWeight.w600),
                      icon: const Icon(Icons.expand_more_rounded,
                          color: AppColors.primary, size: 20),
                      items: _genders.map((g) => DropdownMenuItem(
                              value: g, child: Text(g))).toList(),
                      onChanged: (v) => setState(() => _gender = v),
                      decoration: _dec('เพศ', icon: Icons.pets_outlined),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'กรุณาเลือกเพศ' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── สายพันธุ์ ─────────────────────────────────────────────────
          _label('สายพันธุ์'),
          DropdownButtonFormField<String>(
            value: _breed,
            isExpanded: true,
            menuMaxHeight: 380,
            dropdownColor: Colors.white,
            style: const TextStyle(
                color: AppColors.darkBrown,
                fontSize: 14,
                fontWeight: FontWeight.w600),
            icon: const Icon(Icons.expand_more_rounded,
                color: AppColors.primary, size: 20),
            items: _dogBreeds.map((b) => DropdownMenuItem(
                    value: b,
                    child: Text(b, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (v) {
              setState(() {
                _breed = v;
                _showCustomBreedField = (v == 'อื่นๆ (ระบุเอง)');
                if (!_showCustomBreedField) _customBreedCtrl.clear();
              });
            },
            decoration: _dec('สายพันธุ์', icon: Icons.search_rounded),
            validator: (v) => (v == null || v.isEmpty)
                ? 'กรุณาเลือกสายพันธุ์' : null,
          ),

          // ── ระบุสายพันธุ์เอง ───────────────────────────────────────────
          if (_showCustomBreedField) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _customBreedCtrl,
              style: const TextStyle(
                  color: AppColors.darkBrown,
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              decoration: _dec('ระบุสายพันธุ์',
                  hint: 'เช่น ออสเตรเลียน เชพเพิร์ด',
                  icon: Icons.edit_outlined),
              validator: (v) {
                if (_showCustomBreedField &&
                    (v == null || v.trim().isEmpty)) {
                  return 'กรุณาระบุสายพันธุ์';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Sheet Option ─────────────────────────────────────────────────────────────
class _SheetOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.darkBrown,
  });

  @override
  Widget build(BuildContext context) {
    final isDestructive = color == AppColors.cancelRed;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFEECEC) : AppColors.fieldBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFF5C0C0) : AppColors.fieldBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}