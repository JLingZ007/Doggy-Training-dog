import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/community_models.dart';
import '../../providers/community_provider.dart';
import '../../services/enhanced_image_handler_service.dart';

class EditPostSheet extends StatefulWidget {
  final CommunityPost post;
  const EditPostSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // Media state
  final List<XFile> _newImages = [];
  XFile? _newVideo;
  final Set<String> _imagesToDelete = {};
  bool _removeVideo = false;

  bool _isLoading = false;
  bool _isProcessingImages = false;

  @override
  void initState() {
    super.initState();
    _contentController.text = widget.post.content;
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const SizedBox(height: 20),
                _buildHeader(),
                const SizedBox(height: 20),
                _buildTextField(),
                const SizedBox(height: 16),
                _buildMediaButtons(),
                if (_hasImages()) ...[
                  const SizedBox(height: 16),
                  _buildImagePreview(),
                ],
                if (_hasVideo()) ...[
                  const SizedBox(height: 16),
                  _buildVideoPreview(),
                ],
                const SizedBox(height: 32),
                _buildActionButtons(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ============== WIDGET BUILDERS ==============

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.edit, color: Color(0xFF8B4513), size: 28),
        const SizedBox(width: 12),
        const Text(
          'แก้ไขโพสต์',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF8B4513),
          ),
        ),
        if (_isProcessingImages) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF8B4513)),
          ),
          const SizedBox(width: 8),
          const Text(
            'กำลังประมวลผล...',
            style: TextStyle(color: Color(0xFF8B4513), fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField() {
    return TextField(
      controller: _contentController,
      decoration: InputDecoration(
        hintText: 'แชร์เรื่องราวของคุณกับสมาชิกในกลุ่ม...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 5,
      maxLength: 1000,
    );
  }

  Widget _buildMediaButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildMediaButton(
            icon: Icons.image,
            label: 'รูปภาพ',
            subtitle: 'สูงสุด 10 รูป',
            onTap: _pickImages,
            isSelected: _hasImages(),
            count: (widget.post.images.length - _imagesToDelete.length) + _newImages.length,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMediaButton(
            icon: Icons.videocam,
            label: 'วิดีโอ',
            subtitle: 'สูงสุด 5 นาที',
            onTap: _pickVideo,
            isSelected: _hasVideo(),
          ),
        ),
      ],
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
    final effectiveLabel = count != null && count > 0 ? '$label ($count)' : label;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFD2B48C).withOpacity(0.3)
              : const Color(0xFFD2B48C).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFD2B48C) : Colors.grey[300]!,
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
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    effectiveLabel,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF8B4513) : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    final existingImages = widget.post.images.where((img) => !_imagesToDelete.contains(img.publicId)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...existingImages.map((img) => _buildExistingImageTile(img)),
              ..._newImages.map((file) => _buildNewImageTile(file)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingImageTile(PostImage image) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: image.thumbnailUrl.isNotEmpty ? image.thumbnailUrl : image.mediumUrl,
              fit: BoxFit.cover,
              width: 100,
              height: 100,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _imagesToDelete.add(image.publicId)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewImageTile(XFile imageFile) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(File(imageFile.path), fit: BoxFit.cover, width: 100, height: 100),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _newImages.remove(imageFile)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    if (_newVideo != null) {
      return _buildNewVideoPreview();
    }
    if (widget.post.video != null && !_removeVideo) {
      return _buildExistingVideoPreview();
    }
    return const SizedBox.shrink();
  }

  Widget _buildExistingVideoPreview() {
    final video = widget.post.video!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วิดีโอเดิม', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
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
                  image: video.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(video.thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: Icon(Icons.play_circle_outline, size: 32, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'วิดีโอเดิม: ${video.formattedDuration}',
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => setState(() => _removeVideo = true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewVideoPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วิดีโอใหม่', style: TextStyle(color: Color(0xFF8B4513), fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
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
                child: Icon(Icons.play_circle_outline, size: 32, color: Colors.grey[600]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _newVideo!.name,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => setState(() => _newVideo = null),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading || _isProcessingImages ? null : () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[400]!),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('ยกเลิก', style: TextStyle(color: Colors.grey[600])),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading || _isProcessingImages ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2B48C),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('บันทึก', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // ============== LOGIC METHODS ==============

  bool _hasImages() {
    return (widget.post.images.length - _imagesToDelete.length) + _newImages.length > 0;
  }

  bool _hasVideo() {
    return (_newVideo != null) || (widget.post.video != null && !_removeVideo);
  }

  void _pickImages() async {
    if (_hasVideo()) {
      _showSnackBar('ไม่สามารถเพิ่มรูปภาพได้เมื่อมีวิดีโออยู่');
      return;
    }

    setState(() => _isProcessingImages = true);
    try {
      final images = await _picker.pickMultipleMedia(imageQuality: 85);
      if (images.isEmpty) return;

      final imageFiles = images.where((f) => EnhancedImageHandler.isValidImageFile(f.name)).toList();
      final currentCount = (widget.post.images.length - _imagesToDelete.length) + _newImages.length;
      final canAdd = 10 - currentCount;

      if (canAdd <= 0) {
        _showSnackBar('มีรูปภาพครบ 10 รูปแล้ว');
        return;
      }

      final toAdd = imageFiles.length > canAdd ? imageFiles.sublist(0, canAdd) : imageFiles;

      setState(() => _newImages.addAll(toAdd));

      if (imageFiles.length > toAdd.length) {
        _showSnackBar('เพิ่มได้อีก $canAdd รูปเท่านั้น');
      }
    } catch (e) {
      _showSnackBar('ไม่สามารถเลือกรูปภาพได้: $e');
    } finally {
      setState(() => _isProcessingImages = false);
    }
  }

  void _pickVideo() async {
    if ((widget.post.images.length - _imagesToDelete.length) > 0 || _newImages.isNotEmpty) {
      _showSnackBar('ไม่สามารถเพิ่มวิดีโอได้เมื่อมีรูปภาพอยู่');
      return;
    }
    try {
      final video = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (video == null) return;
      
      final msg = await context.read<CommunityProvider>().validateVideo(video);
      if (msg != null) {
        _showSnackBar(msg);
        return;
      }

      setState(() {
        _newVideo = video;
        _removeVideo = true; // แทนที่วิดีโอเก่าเสมอ
      });
    } catch (e) {
      _showSnackBar('ไม่สามารถเลือกวิดีโอได้: $e');
    }
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty && !_hasImages() && !_hasVideo()) {
      _showSnackBar('กรุณาเพิ่มเนื้อหาหรือสื่อ');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = context.read<CommunityProvider>();
      final ok = await provider.updatePost(
        postId: widget.post.id,
        newContent: _contentController.text.trim(),
        newImageFiles: _newImages.isEmpty ? null : _newImages,
        imagesToDelete: _imagesToDelete.isEmpty ? null : _imagesToDelete.toList(),
        newVideoFile: _newVideo,
        removeVideo: _removeVideo,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('อัปเดตโพสต์เรียบร้อยแล้ว'),
            ]),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _showSnackBar(provider.error ?? 'ไม่สามารถแก้ไขโพสต์ได้');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
}