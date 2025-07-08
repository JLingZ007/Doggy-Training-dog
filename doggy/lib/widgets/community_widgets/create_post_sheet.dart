// widgets/community_widgets/create_post_sheet.dart - Updated for Cloudinary
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import 'dart:io';

class CreatePostSheet extends StatefulWidget {
  final String groupId;

  const CreatePostSheet({Key? key, required this.groupId}) : super(key: key);

  @override
  _CreatePostSheetState createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];  // เปลี่ยนเป็น XFile
  XFile? _selectedVideo;  // เปลี่ยนเป็น XFile
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                
                Row(
                  children: [
                    Icon(Icons.add_box, color: const Color(0xFF8B4513), size: 28),
                    SizedBox(width: 12),
                    Text(
                      'สร้างโพสต์ใหม่',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 20),
                
                TextField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'แชร์เรื่องราวของคุณกับสมาชิกในกลุ่ม...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: EdgeInsets.all(16),
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                ),
                
                SizedBox(height: 16),
                
                // Media options
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaButton(
                        icon: Icons.image,
                        label: 'รูปภาพ',
                        onTap: _pickImages,
                        isSelected: _selectedImages.isNotEmpty,
                        count: _selectedImages.length,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildMediaButton(
                        icon: Icons.videocam,
                        label: 'วิดีโอ',
                        onTap: _pickVideo,
                        isSelected: _selectedVideo != null,
                      ),
                    ),
                  ],
                ),
                
                // Selected media preview
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildImagePreview(),
                ],
                
                if (_selectedVideo != null) ...[
                  SizedBox(height: 16),
                  _buildVideoPreview(),
                ],
                
                // Post type indicator
                if (_getPostType() != PostType.text) ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD2B48C).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getPostType().icon,
                          size: 16,
                          color: const Color(0xFF8B4513),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _getPostType().displayName,
                          style: TextStyle(
                            color: const Color(0xFF8B4513),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading || !_canPost() ? null : _createPost,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2B48C),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12),
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
                                'โพสต์',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isSelected,
    int? count,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFD2B48C).withOpacity(0.3)
              : const Color(0xFFD2B48C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? const Color(0xFFD2B48C)
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              count != null && count > 0 ? '$label ($count)' : label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, size: 16, color: const Color(0xFF8B4513)),
            SizedBox(width: 6),
            Text(
              'รูปภาพที่เลือก (${_selectedImages.length})',
              style: TextStyle(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                });
              },
              child: Text(
                'ลบทั้งหมด',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              return Container(
                width: 100,
                margin: EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(image.path),
                        fit: BoxFit.cover,
                        width: 100,
                        height: 100,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
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
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.videocam, size: 16, color: const Color(0xFF8B4513)),
            SizedBox(width: 6),
            Text(
              'วิดีโอที่เลือก',
              style: TextStyle(
                color: const Color(0xFF8B4513),
                fontWeight: FontWeight.w500,
              ),
            ),
            Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedVideo = null;
                });
              },
              child: Text(
                'ลบ',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.play_circle_outline,
                  size: 32,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedVideo!.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: File(_selectedVideo!.path).length(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final size = snapshot.data!;
                          final sizeStr = _formatFileSize(size);
                          return Text(
                            'ขนาด: $sizeStr',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          );
                        }
                        return Text(
                          'กำลังคำนวณขนาด...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== MEDIA SELECTION METHODS ====================

  void _pickImages() async {
    try {
      final images = await _picker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // กรองเฉพาะไฟล์รูปภาพ
        final imageFiles = images.where((file) {
          final extension = file.path.toLowerCase();
          return extension.endsWith('.jpg') || 
                 extension.endsWith('.jpeg') || 
                 extension.endsWith('.png') || 
                 extension.endsWith('.gif') || 
                 extension.endsWith('.webp');
        }).toList();

        if (imageFiles.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(imageFiles);
            _selectedVideo = null; // Clear video if images selected
            // จำกัดไม่เกิน 10 รูป
            if (_selectedImages.length > 10) {
              _selectedImages.removeRange(10, _selectedImages.length);
              _showSnackBar('สามารถเลือกได้สูงสุด 10 รูปภาพ');
            }
          });
        } else {
          _showSnackBar('กรุณาเลือกไฟล์รูปภาพเท่านั้น');
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      _showSnackBar('ไม่สามารถเลือกรูปภาพได้');
    }
  }

  void _pickVideo() async {
    try {
      final video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(minutes: 5), // จำกัด 5 นาที
      );
      
      if (video != null) {
        // ตรวจสอบขนาดไฟล์
        final file = File(video.path);
        final fileSize = await file.length();
        
        // จำกัดขนาดไฟล์ 100MB
        if (fileSize > 100 * 1024 * 1024) {
          _showSnackBar('ไฟล์วิดีโอใหญ่เกินไป (สูงสุด 100MB)');
          return;
        }

        setState(() {
          _selectedVideo = video;
          _selectedImages.clear(); // Clear images if video selected
        });
      }
    } catch (e) {
      print('Error picking video: $e');
      _showSnackBar('ไม่สามารถเลือกวิดีโอได้');
    }
  }

  // ==================== UTILITY METHODS ====================

  PostType _getPostType() {
    if (_selectedVideo != null && _selectedImages.isNotEmpty) {
      return PostType.mixed;
    } else if (_selectedVideo != null) {
      return PostType.video;
    } else if (_selectedImages.isNotEmpty) {
      return PostType.image;
    } else {
      return PostType.text;
    }
  }

  bool _canPost() {
    return _contentController.text.trim().isNotEmpty || 
           _selectedImages.isNotEmpty || 
           _selectedVideo != null;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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

  // ==================== CREATE POST METHOD ====================

  void _createPost() async {
    if (!_canPost()) {
      _showSnackBar('กรุณาเพิ่มเนื้อหาหรือสื่อ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<CommunityProvider>();
      
      final success = await provider.createPost(
        groupId: widget.groupId,
        content: _contentController.text.trim(),
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        videoFile: _selectedVideo,
        type: _getPostType(),
      );

      if (success) {
        Navigator.pop(context);
        _showSnackBar('สร้างโพสต์เรียบร้อยแล้ว');
      } else {
        _showSnackBar(provider.error ?? 'ไม่สามารถสร้างโพสต์ได้');
      }
    } catch (e) {
      print('Error creating post: $e');
      _showSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}