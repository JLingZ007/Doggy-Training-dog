import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../models/community_models.dart';

class EditGroupDialog extends StatefulWidget {
  final CommunityGroup group;

  const EditGroupDialog({super.key, required this.group});

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtl;
  late final TextEditingController _descCtl;
  final TextEditingController _tagCtl = TextEditingController();

  static const int kMaxTags = 7;
  static const List<String> kSuggestedTags = <String>[
    'ฝึกสุนัข', 'ลูกสุนัข', 'สุขภาพ', 'พฤติกรรม', 'โกลเด้น', 'ชิวาวา', 'บอร์เดอร์คอลลี',
  ];

  late List<String> _tags;
  late bool _isPublic;

  final ImagePicker _picker = ImagePicker();
  XFile? _newCover;                 // รูปใหม่ (ถ้าเลือก)
  String? _existingCoverUrl;        // url เดิม
  bool _removeCover = false;        // กดลบรูป (ไม่มีทั้งเก่า/ใหม่)
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.group.name);
    _descCtl = TextEditingController(text: widget.group.description);
    _tags = List<String>.from(widget.group.tags);
    _isPublic = widget.group.isPublic;
    _existingCoverUrl = widget.group.coverImageUrl;
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _descCtl.dispose();
    _tagCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const themeBrown = Color(0xFF8B4513);
    const themeTan = Color(0xFFD2B48C);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: (MediaQuery.of(context).size.width).clamp(0, 640),
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      const Icon(Icons.edit, color: themeBrown, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'แก้ไขกลุ่ม',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: themeBrown,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.black54),
                        tooltip: 'ปิด',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildCover(themeTan),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameCtl,
                    decoration: _decoration(
                      label: 'ชื่อกลุ่ม *',
                      hint: 'เช่น กลุ่มรักสุนัขพันธุ์โกลเด้น',
                      icon: Icons.pets,
                      themeTan: themeTan,
                      themeBrown: themeBrown,
                    ),
                    maxLength: 50,
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'กรุณาใส่ชื่อกลุ่ม';
                      if (t.length < 3) return 'ชื่อกลุ่มต้องมีอย่างน้อย 3 ตัวอักษร';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descCtl,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: _decoration(
                      label: 'คำอธิบาย *',
                      hint: 'อธิบายเกี่ยวกับกลุ่มของคุณ...',
                      icon: Icons.description,
                      themeTan: themeTan,
                      themeBrown: themeBrown,
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'กรุณาใส่คำอธิบาย';
                      if (t.length < 10) return 'อย่างน้อย 10 ตัวอักษร';
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  _buildTags(themeBrown, themeTan),

                  const SizedBox(height: 20),

                  _buildPrivacy(themeBrown, themeTan),

                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        child: const Text('ยกเลิก'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _submit,
                        icon: _saving
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('บันทึกการแก้ไข'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeTan,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- cover ----------
  Widget _buildCover(Color themeTan) {
    final hasNew = _newCover != null;
    final hasOld = (_existingCoverUrl != null && _existingCoverUrl!.isNotEmpty) && !_removeCover;

    return GestureDetector(
      onTap: () async {
        final img = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1600, maxHeight: 900, imageQuality: 85,
        );
        if (img == null) return;
        final size = await File(img.path).length();
        if (size > 5 * 1024 * 1024) {
          _snack('ไฟล์รูปภาพใหญ่เกินไป (สูงสุด 5MB)');
          return;
        }
        setState(() {
          _newCover = img;
          _removeCover = false; // มีรูปใหม่แล้ว ไม่ถือว่าลบ
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: hasNew
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_newCover!.path), fit: BoxFit.cover),
                      _removeBtn(() => setState(() => _newCover = null)),
                    ],
                  )
                : hasOld
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            _existingCoverUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _emptyCover(themeTan),
                          ),
                          _removeBtn(() => setState(() {
                                _removeCover = true;
                                _newCover = null;
                              })),
                        ],
                      )
                    : _emptyCover(themeTan),
          ),
        ),
      ),
    );
  }

  Widget _emptyCover(Color themeTan) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text('เพิ่ม/เปลี่ยนรูปปก (ไม่บังคับ)',
              style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('อัตราส่วนแนะนำ 16:9', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _removeBtn(VoidCallback onTap) {
    return Positioned(
      top: 8, right: 8,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  // ---------- tags ----------
  Widget _buildTags(Color brown, Color tan) {
    final remaining = kMaxTags - _tags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('แท็ก (สูงสุด $kMaxTags)',
            style: TextStyle(fontWeight: FontWeight.w700, color: brown, fontSize: 16)),
        const SizedBox(height: 10),

        Wrap(
          spacing: 8, runSpacing: 8,
          children: kSuggestedTags.map((t) {
            final selected = _tags.contains(t);
            return FilterChip(
              label: Text(t),
              selected: selected,
              onSelected: (v) => v ? _addTag(t) : _removeTag(t),
              selectedColor: tan,
              backgroundColor: tan.withOpacity(0.25),
              labelStyle: TextStyle(
                color: selected ? Colors.black : brown,
                fontWeight: FontWeight.w600,
              ),
              side: BorderSide(color: tan),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              checkmarkColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagCtl,
                decoration: _decoration(
                  label: 'เพิ่มแท็กเอง',
                  hint: 'เช่น โกลเด้น, ฝึกสุนัข, ดูแลสุนัข',
                  icon: Icons.tag,
                  themeTan: tan,
                  themeBrown: brown,
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addTag(_tagCtl.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: tan, foregroundColor: Colors.black,
                shape: const CircleBorder(), padding: const EdgeInsets.all(12), elevation: 0,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text('เลือกแล้ว ${_tags.length}/$kMaxTags (เหลือ $remaining)',
            style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),

        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _tags.map((t) {
              return Chip(
                label: Text(t),
                onDeleted: () => _removeTag(t),
                backgroundColor: Colors.brown.withOpacity(0.05),
                deleteIconColor: brown,
                labelStyle: TextStyle(color: brown, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: tan),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  // ---------- privacy ----------
  Widget _buildPrivacy(Color brown, Color tan) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('การตั้งค่าความเป็นส่วนตัว',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: brown)),
          const SizedBox(height: 6),
          RadioListTile<bool>(
            title: const Text('กลุ่มสาธารณะ'),
            subtitle: const Text('ทุกคนสามารถเห็นและเข้าร่วมกลุ่มได้', style: TextStyle(fontSize: 12)),
            value: true, groupValue: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v!),
            activeColor: tan, contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text('กลุ่มส่วนตัว'),
            subtitle: const Text('เฉพาะสมาชิกเท่านั้นที่เห็นเนื้อหา', style: TextStyle(fontSize: 12)),
            value: false, groupValue: _isPublic,
            onChanged: (v) => setState(() => _isPublic = v!),
            activeColor: tan, contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ---------- utils ----------
  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color themeTan,
    required Color themeBrown,
  }) {
    return InputDecoration(
      labelText: label, hintText: hint,
      prefixIcon: Icon(icon, color: themeBrown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeTan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isEmpty) return;
    if (_tags.contains(t)) { _snack('แท็กนี้มีอยู่แล้ว'); _tagCtl.clear(); return; }
    if (_tags.length >= kMaxTags) { _snack('เพิ่มแท็กได้สูงสุด $kMaxTags แท็ก'); _tagCtl.clear(); return; }
    setState(() { _tags.add(t); _tagCtl.clear(); });
  }

  void _removeTag(String t) => setState(() => _tags.remove(t));

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final provider = context.read<CommunityProvider>();

      final ok = await provider.updateGroup(
        groupId: widget.group.id,
        name: _nameCtl.text.trim(),
        description: _descCtl.text.trim(),
        tags: _tags,
        newCoverImage: _newCover,              // XFile? (อัปโหลดใน service)
        removeCoverImage: _removeCover,        // true = เคลียร์ cover
      );

      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8),
              Text('อัปเดตกลุ่มเรียบร้อยแล้ว'),
            ]),
            backgroundColor: Colors.green, behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _snack(provider.error ?? 'ไม่สามารถแก้ไขกลุ่มได้');
      }
    } catch (e) {
      _snack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
