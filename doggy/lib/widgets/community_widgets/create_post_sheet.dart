// widgets/community_widgets/create_post_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/community_provider.dart';
import 'dart:io';

class CreatePostSheet extends StatefulWidget {
  final String groupId;

  const CreatePostSheet({Key? key, required this.groupId}) : super(key: key);

  @override
  _CreatePostSheetState createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<CreatePostSheet> {
  final _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  File? _selectedVideo;
  final ImagePicker _picker = ImagePicker();

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
                  ),
                  maxLines: 5,
                  maxLength: 1000,
                ),
                
                SizedBox(height: 16),
                
                // Media options
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickImages,
                        icon: Icon(Icons.image, color: Colors.black),
                        label: Text(
                          'รูปภาพ',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2B48C).withOpacity(0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _pickVideo,
                        icon: Icon(Icons.videocam, color: Colors.black),
                        label: Text(
                          'วิดีโอ',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2B48C).withOpacity(0.3),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Selected media preview
                if (_selectedImages.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Text(
                    'รูปภาพที่เลือก (${_selectedImages.length})',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImages[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
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
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20,
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
                
                if (_selectedVideo != null) ...[
                  SizedBox(height: 16),
                  Text(
                    'วิดีโอที่เลือก',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(Icons.play_circle_fill, size: 50),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedVideo = null;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
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
                        onPressed: () => Navigator.pop(context),
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
                      child: Consumer<CommunityProvider>(
                        builder: (context, provider, child) {
                          return ElevatedButton(
                            onPressed: provider.isLoading ? null : _createPost,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD2B48C),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: provider.isLoading
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
                          );
                        },
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

  void _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)));
        _selectedVideo = null; // Clear video if images selected
      });
    }
  }

  void _pickVideo() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _selectedVideo = File(video.path);
        _selectedImages.clear(); // Clear images if video selected
      });
    }
  }

  void _createPost() async {
    final content = _contentController.text.trim();
    
    if (content.isEmpty && _selectedImages.isEmpty && _selectedVideo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กรุณาเพิ่มเนื้อหาหรือสื่อ'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    final provider = context.read<CommunityProvider>();
    final success = await provider.createPost(
      groupId: widget.groupId,
      content: content,
      imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
      videoFile: _selectedVideo,
    );

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('สร้างโพสต์เรียบร้อยแล้ว'),
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
              Text(provider.error ?? 'ไม่สามารถสร้างโพสต์ได้'),
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