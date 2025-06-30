// widgets/community_widgets/create_group_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  final List<String> _tags = [];
  final _tagController = TextEditingController();

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
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_add, color: const Color(0xFF8B4513), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'สร้างกลุ่มใหม่',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                
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
                
                SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'ยกเลิก',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD2B48C),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
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

  void _addTag(String tag) {
    final cleanTag = tag.trim();
    if (cleanTag.isNotEmpty && !_tags.contains(cleanTag) && _tags.length < 5) {
      setState(() {
        _tags.add(cleanTag);
        _tagController.clear();
      });
    } else if (_tags.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('สามารถเพิ่มแท็กได้สูงสุด 5 แท็ก')),
      );
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _createGroup() async {
    if (_formKey.currentState?.validate() == true) {
      final group = CommunityGroup(
        id: '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        memberIds: [],
        tags: _tags,
        createdBy: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final provider = context.read<CommunityProvider>();
      final success = await provider.createGroup(group);

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('สร้างกลุ่มเรียบร้อยแล้ว'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(provider.error ?? 'ไม่สามารถสร้างกลุ่มได้'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}