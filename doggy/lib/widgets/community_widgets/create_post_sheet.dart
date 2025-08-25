// widgets/community_widgets/create_post_sheet.dart - Enhanced for HEIC Support
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import '../../services/enhanced_image_handler_service.dart';
import 'dart:io';

class CreatePostSheet extends StatefulWidget {
  final String groupId;

  const CreatePostSheet({Key? key, required this.groupId}) : super(key: key);

  @override
  _CreatePostSheetState createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final List<XFile> _selectedImages = [];
  XFile? _selectedVideo;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isProcessingImages = false;
  List<Map<String, dynamic>> _imageAnalysis = [];

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
                    if (_isProcessingImages) ...[
                      SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'กำลังประมวลผล...',
                        style: TextStyle(
                          color: const Color(0xFF8B4513),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
                
                // Media options with HEIC support indicator
                Row(
                  children: [
                    Expanded(
                      child: _buildMediaButton(
                        icon: Icons.image,
                        label: 'รูปภาพ',
                        subtitle: 'สูงสุด 10 รูป',
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
                        subtitle: 'สูงสุด 5 นาที',
                        onTap: _pickVideo,
                        isSelected: _selectedVideo != null,
                      ),
                    ),
                  ],
                ),
                
                // // Image analysis results
                // if (_imageAnalysis.isNotEmpty) ...[
                //   SizedBox(height: 16),
                //   _buildImageAnalysisCard(),
                // ],
                
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
                          _getPostType() == PostType.text ? Icons.text_fields :
                          _getPostType() == PostType.image ? Icons.image :
                          _getPostType() == PostType.video ? Icons.videocam : Icons.collections,
                          size: 16,
                          color: const Color(0xFF8B4513),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _getPostType() == PostType.text ? 'ข้อความ' :
                          _getPostType() == PostType.image ? 'รูปภาพ' :
                          _getPostType() == PostType.video ? 'วิดีโอ' : 'ผสม',
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
                        onPressed: _isLoading || _isProcessingImages 
                            ? null 
                            : () => Navigator.pop(context),
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
                        onPressed: _isLoading || _isProcessingImages || !_canPost() 
                            ? null 
                            : _createPost,
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
    String? subtitle,
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
                  size: 20,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    count != null && count > 0 ? '$label ($count)' : label,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ],
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
                  _imageAnalysis.clear();
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
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              final image = _selectedImages[index];
              final analysis = index < _imageAnalysis.length ? _imageAnalysis[index] : null;
              
              return Container(
                width: 100,
                margin: EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(image.path),
                              fit: BoxFit.cover,
                              width: 100,
                            ),
                          ),
                        ),
                        if (analysis != null) ...[
                          SizedBox(height: 4),
                          Container(
                            width: 100,
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            child: Column(
                              children: [
                                if (analysis['isHeif'] == true)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[200],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'HEIC',
                                      style: TextStyle(fontSize: 8, color: Colors.orange[800]),
                                    ),
                                  ),
                                Text(
                                  analysis['sizeFormatted'] ?? '',
                                  style: TextStyle(fontSize: 8, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImages.removeAt(index);
                            if (index < _imageAnalysis.length) {
                              _imageAnalysis.removeAt(index);
                            }
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
    setState(() {
      _isProcessingImages = true;
    });

    try {
      final images = await _picker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        // กรองเฉพาะไฟล์รูปภาพ
        final imageFiles = images.where((file) {
          return EnhancedImageHandler.isValidImageFile(file.name);
        }).toList();

        if (imageFiles.isNotEmpty) {
          // วิเคราะห์ไฟล์ทั้งหมด
          List<Map<String, dynamic>> analysisResults = [];
          for (final imageFile in imageFiles) {
            final analysis = await EnhancedImageHandler.analyzeImageFile(imageFile);
            analysisResults.add(analysis);
          }

          setState(() {
            _selectedImages.addAll(imageFiles);
            _imageAnalysis.addAll(analysisResults);
            _selectedVideo = null; // Clear video if images selected
            
            // จำกัดไม่เกิน 10 รูป
            if (_selectedImages.length > 10) {
              final excess = _selectedImages.length - 10;
              _selectedImages.removeRange(10, _selectedImages.length);
              _imageAnalysis.removeRange(10, _imageAnalysis.length);
              _showSnackBar('สามารถเลือกได้สูงสุด 10 รูปภาพ (ลบ $excess รูป)');
            }
          });

          
        } else {
          _showSnackBar('กรุณาเลือกไฟล์รูปภาพเท่านั้น');
        }
      }
    } catch (e) {
      print('Error picking images: $e');
      _showSnackBar('ไม่สามารถเลือกรูปภาพได้');
    } finally {
      setState(() {
        _isProcessingImages = false;
      });
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
          _imageAnalysis.clear();
        });

        _showSnackBar('เลือกวิดีโอเรียบร้อย (${_formatFileSize(fileSize)})');
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

  void _showSnackBar(String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? Duration(seconds: 3),
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
      
      // แสดงข้อมูลก่อนการอัปโหลด
      if (_selectedImages.isNotEmpty) {
        final heicCount = _imageAnalysis.where((a) => a['isHeif'] == true).length;
        if (heicCount > 0) {
          _showSnackBar('กำลังประมวลผลไฟล์ HEIC/HEIF $heicCount ไฟล์...', 
                       duration: Duration(seconds: 5));
        }
      }

      final success = await provider.createPost(
        groupId: widget.groupId,
        content: _contentController.text.trim(),
        imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        videoFile: _selectedVideo,
        type: _getPostType(),
      );

      if (success) {
        // ทำความสะอาดไฟล์ชั่วคราว
        await EnhancedImageHandler.cleanupTempFiles();
        
        Navigator.pop(context);
        _showSnackBar('สร้างโพสต์เรียบร้อยแล้ว 🎉');
      } else {
        _showSnackBar(provider.error ?? 'ไม่สามารถสร้างโพสต์ได้');
      }
    } catch (e) {
      print('Error creating post: $e');
      
      String errorMessage = 'เกิดข้อผิดพลาด'; 
      _showSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}