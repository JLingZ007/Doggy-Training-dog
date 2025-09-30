import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../providers/community_provider.dart';
import '../../models/community_models.dart';

class CreateGroupDialog extends StatefulWidget {
  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  // ปรับ: จำกัดจำนวนแท็กและกำหนดรายการแท็กแนะนำ 7 รายการ
  static const int kMaxTags = 7;
  static const List<String> kSuggestedTags = <String>[
    'ฝึกสุนัข',
    'ลูกสุนัข',
    'สุขภาพ',
    'พฤติกรรม',
    'โกลเด้น',
    'ชิวาวา',
    'บอร์เดอร์คอลลี',
  ];

  final List<String> _tags = [];
  XFile? _coverImage;
  bool _isPublic = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeBrown = const Color(0xFF8B4513);
    final themeTan = const Color(0xFFD2B48C);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // ปรับความกว้างสูงสุดให้ดูสมส่วนบนจอใหญ่
          final maxW = constraints.maxWidth.clamp(0, 640).toDouble();
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxW, // กว้างสุด ~640px
              // สูงสุด 85% ของจอ (ตัว Dialog จะคุมเองตามจอ)
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(Icons.group_add, color: themeBrown, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'สร้างกลุ่มใหม่',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: themeBrown,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close, color: Colors.grey[700]),
                            tooltip: 'ปิด',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Cover image (สัดส่วน 16:9 ดูสมส่วนขึ้น)
                      _buildCoverImage(themeTan),

                      const SizedBox(height: 20),

                      // Group name
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration(
                          label: 'ชื่อกลุ่ม *',
                          hint: 'เช่น กลุ่มรักสุนัขพันธุ์โกลเด้น',
                          icon: Icons.pets,
                          themeBrown: themeBrown,
                          themeTan: themeTan,
                        ),
                        maxLength: 50,
                        validator: (value) {
                          if (value?.trim().isEmpty == true) {
                            return 'กรุณาใส่ชื่อกลุ่ม';
                          }
                          if (value!.trim().length < 3) {
                            return 'ชื่อกลุ่มต้องมีอย่างน้อย 3 ตัวอักษร';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _inputDecoration(
                          label: 'คำอธิบาย *',
                          hint: 'อธิบายเกี่ยวกับกลุ่มของคุณ...',
                          icon: Icons.description,
                          themeBrown: themeBrown,
                          themeTan: themeTan,
                        ),
                        maxLines: 3,
                        maxLength: 200,
                        validator: (value) {
                          if (value?.trim().isEmpty == true) {
                            return 'กรุณาใส่คำอธิบาย';
                          }
                          if (value!.trim().length < 10) {
                            return 'คำอธิบายต้องมีอย่างน้อย 10 ตัวอักษร';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tags section: แท็กแนะนำ + กรอกเอง + รายการที่เลือก
                      _buildTagsSection(themeBrown, themeTan),

                      const SizedBox(height: 20),

                      // Privacy settings
                      _buildPrivacy(themeBrown, themeTan),

                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: Text(
                              'ยกเลิก',
                              style: TextStyle(color: Colors.grey[700], fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _isLoading || !_canCreateGroup()
                                ? null
                                : _createGroup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeTan,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Text(
                                    'สร้างกลุ่ม',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== UI BUILDERS ====================

  Widget _buildCoverImage(Color themeTan) {
    return GestureDetector(
      onTap: _pickCoverImage,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _coverImage != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(
                        File(_coverImage!.path),
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _coverImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate,
                            size: 40, color: Colors.grey[700]),
                        const SizedBox(height: 8),
                        Text(
                          'เพิ่มรูปปกกลุ่ม (ไม่บังคับ)',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'อัตราส่วนที่แนะนำ 16:9',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection(Color themeBrown, Color themeTan) {
    final remaining = kMaxTags - _tags.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'แท็ก (เลือกได้สูงสุด $kMaxTags)',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: themeBrown,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 10),

        // แท็กแนะนำ 7 รายการ แบบ FilterChip (กดเลือก/ยกเลิก)
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kSuggestedTags.map((tag) {
            final selected = _tags.contains(tag);
            return FilterChip(
              selected: selected,
              label: Text(tag),
              labelStyle: TextStyle(
                color: selected ? Colors.black : themeBrown,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (value) {
                if (value) {
                  _addTag(tag);
                } else {
                  _removeTag(tag);
                }
              },
              selectedColor: themeTan,
              backgroundColor: themeTan.withOpacity(0.25),
              checkmarkColor: Colors.black,
              side: BorderSide(color: themeTan),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            );
          }).toList(),
        ),

        const SizedBox(height: 12),

        // เพิ่มเองผ่าน TextField
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: _inputDecoration(
                  label: 'เพิ่มแท็กเอง',
                  hint: 'เช่น โกลเด้น, ฝึกสุนัข, ดูแลสุนัข',
                  icon: Icons.tag,
                  themeBrown: themeBrown,
                  themeTan: themeTan,
                ),
                onFieldSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _addTag(_tagController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeTan,
                foregroundColor: Colors.black,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                elevation: 0,
              ),
              child: const Icon(Icons.add),
            ),
          ],
        ),

        const SizedBox(height: 8),
        Text(
          'เลือกแล้ว ${_tags.length}/$kMaxTags  (เหลือได้อีก $remaining)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),

        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () => _removeTag(tag),
                backgroundColor: themeTan.withOpacity(0.25),
                deleteIconColor: themeBrown,
                labelStyle: TextStyle(
                  color: themeBrown,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: themeTan),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildPrivacy(Color themeBrown, Color themeTan) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'การตั้งค่าความเป็นส่วนตัว',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: themeBrown,
            ),
          ),
          const SizedBox(height: 6),
          RadioListTile<bool>(
            title: const Text('กลุ่มสาธารณะ'),
            subtitle: const Text(
              'ทุกคนสามารถเห็นและเข้าร่วมกลุ่มได้',
              style: TextStyle(fontSize: 12),
            ),
            value: true,
            groupValue: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value!),
            activeColor: themeTan,
            contentPadding: EdgeInsets.zero,
          ),
          RadioListTile<bool>(
            title: const Text('กลุ่มส่วนตัว'),
            subtitle: const Text(
              'เฉพาะสมาชิกเท่านั้นที่เห็นเนื้อหา',
              style: TextStyle(fontSize: 12),
            ),
            value: false,
            groupValue: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value!),
            activeColor: themeTan,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  // ==================== DECORATION ====================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color themeBrown,
    required Color themeTan,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: themeBrown),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: themeTan, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    );
    // หมายเหตุ: ไม่ใช้ fillColor เพื่อคุม contrast ให้ดูสะอาดตา
  }

  // ==================== COVER IMAGE METHODS ====================

  Future<void> _pickCoverImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('ไฟล์รูปภาพใหญ่เกินไป (สูงสุด 5MB)');
          return;
        }

        setState(() {
          _coverImage = image;
        });
      }
    } catch (e) {
      debugPrint('Error picking cover image: $e');
      _showSnackBar('ไม่สามารถเลือกรูปภาพได้');
    }
  }

  // ==================== TAG METHODS ====================

  void _addTag(String tag) {
    final clean = tag.trim();
    if (clean.isEmpty) return;

    if (_tags.contains(clean)) {
      _showSnackBar('แท็กนี้มีอยู่แล้ว');
      _tagController.clear();
      return;
    }
    if (_tags.length >= kMaxTags) {
      _showSnackBar('สามารถเพิ่มแท็กได้สูงสุด $kMaxTags แท็ก');
      _tagController.clear();
      return;
    }

    setState(() {
      _tags.add(clean);
      _tagController.clear();
    });
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  // ==================== UTILITY METHODS ====================

  bool _canCreateGroup() {
    return _nameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text('สร้างกลุ่มเรียบร้อยแล้ว')),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== CREATE GROUP METHOD ====================

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate() || !_canCreateGroup()) return;

    setState(() => _isLoading = true);

    try {
      final provider = context.read<CommunityProvider>();

      final dto = CreateGroupDto(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        isPublic: _isPublic,
        coverImageFile: _coverImage,
      );

      final success = await provider.createGroup(dto);

      if (success) {
        Navigator.pop(context);
        _showSuccessSnackBar('สร้างกลุ่มเรียบร้อยแล้ว');
      } else {
        _showErrorSnackBar(provider.error ?? 'ไม่สามารถสร้างกลุ่มได้');
      }
    } catch (e) {
      debugPrint('Error creating group: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
