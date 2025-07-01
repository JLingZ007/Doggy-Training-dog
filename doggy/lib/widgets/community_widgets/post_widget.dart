// widgets/community_widgets/post_widget.dart - อัพเดทสำหรับ Base64 Images
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import 'comments_sheet.dart';

class PostWidget extends StatelessWidget {
  final CommunityPost post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Info
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildAuthorAvatar(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        _formatDate(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        _reportPost(context);
                        break;
                      case 'delete':
                        _deletePost(context);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('รายงาน'),
                        ],
                      ),
                    ),
                    if (context.read<CommunityProvider>().communityService.currentUserId == post.authorId)
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('ลบ', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          
          // Content
          if (post.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.grey[800],
                ),
              ),
            ),
          
          // Images (รองรับทั้ง URL และ Base64)
          if (post.hasImages) ...[
            SizedBox(height: 12),
            _buildImageSection(),
          ],
          
          // Video (รองรับทั้ง URL และ Base64)
          if (post.videoUrl != null || post.videoBase64 != null) ...[
            SizedBox(height: 12),
            _buildVideoSection(),
          ],
          
          // Actions
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    final isLiked = post.likedBy.contains(
                      provider.communityService.currentUserId,
                    );
                    
                    return InkWell(
                      onTap: () => provider.togglePostLike(post.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey[600],
                              size: 22,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '${post.likeCount}',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 16),
                InkWell(
                  onTap: () => _showCommentsSheet(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          color: Colors.grey[600],
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          '${post.commentCount}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 16),
                InkWell(
                  onTap: () => _sharePost(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(
                      Icons.share_outlined,
                      color: Colors.grey[600],
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== AUTHOR AVATAR ====================

  Widget _buildAuthorAvatar() {
    // ลำดับความสำคัญ: Base64 > URL > Default
    if (post.authorAvatarBase64 != null) {
      return _buildBase64Avatar(post.authorAvatarBase64!);
    } else if (post.authorAvatar != null) {
      return _buildNetworkAvatar(post.authorAvatar!);
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildBase64Avatar(String base64String) {
    try {
      final bytes = _decodeBase64(base64String);
      if (bytes != null) {
        return CircleAvatar(
          radius: 22,
          backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
          backgroundColor: const Color(0xFFD2B48C),
        );
      }
    } catch (e) {
      print('Error displaying base64 avatar: $e');
    }
    return _buildDefaultAvatar();
  }

  Widget _buildNetworkAvatar(String url) {
    return CircleAvatar(
      radius: 22,
      backgroundImage: NetworkImage(url),
      backgroundColor: const Color(0xFFD2B48C),
      onBackgroundImageError: (exception, stackTrace) {
        print('Error loading network avatar: $exception');
      },
      child: null,
    );
  }

  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFD2B48C),
      child: Icon(Icons.person, color: Colors.white, size: 26),
    );
  }

  // ==================== IMAGE SECTION ====================

  Widget _buildImageSection() {
    final allImages = post.allImages; // ใช้ helper method จาก model
    
    if (allImages.isEmpty) return SizedBox.shrink();

    return Container(
      height: 250,
      child: allImages.length == 1
          ? _buildSingleImage(allImages[0])
          : _buildImageCarousel(allImages),
    );
  }

  Widget _buildSingleImage(String imageSource) {
    if (_isBase64String(imageSource)) {
      return _buildBase64Image(imageSource);
    } else {
      return _buildNetworkImage(imageSource);
    }
  }

  Widget _buildImageCarousel(List<String> images) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildSingleImage(images[index]),
          ),
        );
      },
    );
  }

  Widget _buildBase64Image(String base64String) {
    try {
      final bytes = _decodeBase64(base64String);
      if (bytes != null) {
        return Image.memory(
          Uint8List.fromList(bytes),
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('Error displaying base64 image: $error');
            return _buildImageError();
          },
        );
      }
    } catch (e) {
      print('Error decoding base64 image: $e');
    }
    return _buildImageError();
  }

  Widget _buildNetworkImage(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading network image: $error');
        return _buildImageError();
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                : null,
            color: const Color(0xFFD2B48C),
          ),
        );
      },
    );
  }

  Widget _buildImageError() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
            SizedBox(height: 8),
            Text(
              'ไม่สามารถโหลดรูปภาพได้',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VIDEO SECTION ====================

  Widget _buildVideoSection() {
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _playVideo(),
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail หรือ placeholder
            if (post.videoBase64 != null)
              _buildBase64VideoThumbnail()
            else
              _buildNetworkVideoThumbnail(),
            
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'แตะเพื่อเล่นวิดีโอ',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBase64VideoThumbnail() {
    // สำหรับ Base64 video ใช้ placeholder เนื่องจากไม่สามารถสร้าง thumbnail ได้ง่าย
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.videocam,
          size: 60,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  Widget _buildNetworkVideoThumbnail() {
    // สำหรับ Network video ใช้ placeholder
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[800]!, Colors.grey[900]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.videocam,
          size: 60,
          color: Colors.white.withOpacity(0.7),
        ),
      ),
    );
  }

  // ==================== UTILITY METHODS ====================

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  bool _isBase64String(String str) {
    return str.startsWith('data:') && str.contains('base64,');
  }

  List<int>? _decodeBase64(String base64String) {
    try {
      if (base64String.contains('base64,')) {
        final base64Data = base64String.split('base64,')[1];
        return base64.decode(base64Data);
      }
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  // ==================== ACTION METHODS ====================

  void _showCommentsSheet(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsSheet(post: post),
    );
  }

  void _sharePost(BuildContext context, CommunityPost post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.share, color: Colors.white),
            SizedBox(width: 8),
            Text('ฟีเจอร์แชร์กำลังพัฒนา'),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _playVideo() {
    // TODO: Implement video player
    // สำหรับ Base64 video ต้องแปลงกลับเป็น bytes แล้วเล่น
    // สำหรับ Network video ใช้ URL โดยตรง
    print('Playing video: ${post.videoUrl ?? 'Base64 Video'}');
    
    // ตัวอย่างการใช้งาน video player package
    /*
    if (post.videoBase64 != null) {
      // Convert Base64 to file or bytes and play
      final bytes = _decodeBase64(post.videoBase64!);
      if (bytes != null) {
        // Play from memory
      }
    } else if (post.videoUrl != null) {
      // Play from URL
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerPage(url: post.videoUrl!),
        ),
      );
    }
    */
  }

  void _reportPost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.flag, color: Colors.red),
            SizedBox(width: 8),
            Text('รายงานโพสต์'),
          ],
        ),
        content: Text('คุณต้องการรายงานโพสต์นี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('ส่งรายงานเรียบร้อยแล้ว'),
                    ],
                  ),
                  backgroundColor: Colors.orange[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('รายงาน'),
          ),
        ],
      ),
    );
  }

  void _deletePost(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red),
            SizedBox(width: 8),
            Text('ลบโพสต์'),
          ],
        ),
        content: Text(
          'คุณต้องการลบโพสต์นี้หรือไม่?\nการดำเนินการนี้ไม่สามารถยกเลิกได้',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // แสดง loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFD2B48C),
                  ),
                ),
              );
              
              final provider = context.read<CommunityProvider>();
              final success = await provider.deletePost(post.id, post.groupId);
              
              // ปิด loading
              Navigator.pop(context);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 8),
                        Text('ลบโพสต์เรียบร้อยแล้ว'),
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
                        Text(provider.error ?? 'ไม่สามารถลบโพสต์ได้'),
                      ],
                    ),
                    backgroundColor: Colors.red[600],
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}