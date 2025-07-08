// widgets/community_widgets/create_group_dialog.dart - Updated for Cloudinary
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import 'dart:io';

class CreateGroupDialog extends StatefulWidget {
  @override
  _CreateGroupDialogState createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _tags = [];
  final _tagController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(24),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.group_add, color: const Color(0xFF8B4513), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'สร้างกลุ่มใหม่',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                
                // Cover image section
                GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                      color: Colors.grey[100],
                    ),
                    child: _coverImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Image.file(
                                  File(_coverImage!.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 120,
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
                                      padding: EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 40,
                                color: Colors.grey[600],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'เพิ่มรูปปกกลุ่ม',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '(ไม่บังคับ)',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                SizedBox(height: 20),
                
                // Group name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อกลุ่ม *',
                    hintText: 'เช่น กลุ่มรักสุนัขพันธุ์โกลเด้น',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD2B48C), width: 2),
                    ),
                    prefixIcon: Icon(Icons.pets, color: const Color(0xFF8B4513)),
                  ),
                  maxLength: 50,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'กรุณาใส่ชื่อกลุ่ม';
                    }
                    if (value!.length < 3) {
                      return 'ชื่อกลุ่มต้องมีอย่างน้อย 3 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 16),
                
                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'คำอธิบาย *',
                    hintText: 'อธิบายเกี่ยวกับกลุ่มของคุณ...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: const Color(0xFFD2B48C), width: 2),
                    ),
                    prefixIcon: Icon(Icons.description, color: const Color(0xFF8B4513)),
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  validator: (value) {
                    if (value?.isEmpty == true) {
                      return 'กรุณาใส่คำอธิบาย';
                    }
                    if (value!.length < 10) {
                      return 'คำอธิบายต้องมีอย่างน้อย 10 ตัวอักษร';
                    }
                    return null;
                  },
                ),
                
                SizedBox(height: 20),
                
                // Tags section
                Text(
                  'แท็ก (เพิ่มเติม)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B4513),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _tagController,
                        decoration: InputDecoration(
                          hintText: 'เช่น โกลเด้น, ฝึกสุนัข, ดูแลสุนัข',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color(0xFFD2B48C), width: 2),
                          ),
                          prefixIcon: Icon(Icons.tag, color: const Color(0xFF8B4513)),
                        ),
                        onFieldSubmitted: _addTag,
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _addTag(_tagController.text),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2B48C),
                        foregroundColor: Colors.black,
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                      child: Icon(Icons.add),
                    ),
                  ],
                ),
                
                if (_tags.isNotEmpty) ...[
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: const Color(0xFFD2B48C).withOpacity(0.2),
                      deleteIconColor: const Color(0xFF8B4513),
                      labelStyle: TextStyle(color: const Color(0xFF8B4513)),
                    )).toList(),
                  ),
                ],
                
                SizedBox(height: 20),
                
                // Privacy settings
                Container(
                  padding: EdgeInsets.all(16),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      SizedBox(height: 12),
                      RadioListTile<bool>(
                        title: Text('กลุ่มสาธารณะ'),
                        subtitle: Text(
                          'ทุกคนสามารถเห็นและเข้าร่วมกลุ่มได้',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: true,
                        groupValue: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value!;
                          });
                        },
                        activeColor: const Color(0xFFD2B48C),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile<bool>(
                        title: Text('กลุ่มส่วนตัว'),
                        subtitle: Text(
                          'เฉพาะสมาชิกเท่านั้นที่เห็นเนื้อหา',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: false,
                        groupValue: _isPublic,
                        onChanged: (value) {
                          setState(() {
                            _isPublic = value!;
                          });
                        },
                        activeColor: const Color(0xFFD2B48C),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isLoading || !_canCreateGroup() ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2B48C),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'สร้างกลุ่ม',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
  }

  // ==================== COVER IMAGE METHODS ====================

  Future<void> _pickCoverImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 400,
        imageQuality: 85,
      );
      
      if (image != null) {
        // ตรวจสอบขนาดไฟล์
        final file = File(image.path);
        final fileSize = await file.length();
        
        // จำกัดขนาดไฟล์ 5MB สำหรับรูปปก
        if (fileSize > 5 * 1024 * 1024) {
          _showSnackBar('ไฟล์รูปภาพใหญ่เกินไป (สูงสุด 5MB)');
          return;
        }

        setState(() {
          _coverImage = image;
        });
      }
    } catch (e) {
      print('Error picking cover image: $e');
      _showSnackBar('ไม่สามารถเลือกรูปภาพได้');
    }
  }

  // ==================== TAG METHODS ====================

  void _addTag(String tag) {
    final cleanTag = tag.trim();
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag) && _tags.length < 5) {
      setState(() {
        _tags.add(cleanTag);
        _tagController.clear();
      });
    } else if (_tags.length >= 5) {
      _showSnackBar('สามารถเพิ่มแท็กได้สูงสุด 5 แท็ก');
    } else if (_tags.contains(cleanTag)) {
      _showSnackBar('แท็กนี้มีอยู่แล้ว');
    }
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

  // ==================== CREATE GROUP METHOD ====================

  void _createGroup() async {
    if (!_formKey.currentState!.validate() || !_canCreateGroup()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<CommunityProvider>();
      
      // สร้าง DTO สำหรับส่งข้อมูล
      final groupDto = CreateGroupDto(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        tags: _tags,
        isPublic: _isPublic,
        coverImageFile: _coverImage,
      );

      final success = await provider.createGroup(groupDto);

      if (success) {
        Navigator.pop(context);
        _showSuccessSnackBar('สร้างกลุ่มเรียบร้อยแล้ว');
      } else {
        _showErrorSnackBar(provider.error ?? 'ไม่สามารถสร้างกลุ่มได้');
      }
    } catch (e) {
      print('Error creating group: $e');
      _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
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
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}