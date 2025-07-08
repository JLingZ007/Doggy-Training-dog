// widgets/community_widgets/post_widget.dart - Fixed version
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import '../../services/cloudinary_service.dart';
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
          
          // Images from Cloudinary
          if (post.hasImages) ...[
            SizedBox(height: 12),
            _buildImageSection(context),
          ],
          
          // Video from Cloudinary
          if (post.hasVideo) ...[
            SizedBox(height: 12),
            _buildVideoSection(context),
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
    if (post.authorAvatar != null) {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFD2B48C),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: CachedNetworkImage(
            imageUrl: post.authorAvatar!,
            width: 44,
            height: 44,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFFD2B48C),
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFD2B48C),
              child: Icon(Icons.person, color: Colors.white, size: 26),
            ),
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFD2B48C),
        child: Icon(Icons.person, color: Colors.white, size: 26),
      );
    }
  }

  // ==================== IMAGE SECTION ====================

  Widget _buildImageSection(BuildContext context) {
    if (post.images.isEmpty) return SizedBox.shrink();

    return Container(
      height: 250,
      child: post.images.length == 1
          ? _buildSingleImage(context, post.images[0])
          : _buildImageCarousel(context, post.images),
    );
  }

  Widget _buildSingleImage(BuildContext context, PostImage image) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _showImageViewer(context, [image], 0),
          child: Hero(
            tag: 'image_${image.publicId}',
            child: CachedNetworkImage(
              imageUrl: image.mediumUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFFD2B48C),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => _buildImageError(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(BuildContext context, List<PostImage> images) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        final image = images[index];
        return Container(
          margin: EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showImageViewer(context, images, index),
              child: Hero(
                tag: 'image_${image.publicId}',
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: image.mediumUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 250,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[300],
                        child: Center(
                          child: CircularProgressIndicator(
                            color: const Color(0xFFD2B48C),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => _buildImageError(),
                    ),
                    // Image counter overlay
                    if (images.length > 1)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${index + 1}/${images.length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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

  Widget _buildVideoSection(BuildContext context) {
    if (post.video == null) return SizedBox.shrink();

    final video = post.video!;
    
    return Container(
      height: 200,
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () => _playVideo(context, video),
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail
              if (video.thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (context, url) => _buildVideoPlaceholder(),
                  errorWidget: (context, url, error) => _buildVideoPlaceholder(),
                )
              else
                _buildVideoPlaceholder(),
              
              // Dark overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              
              // Play button and info
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
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          video.formattedDuration,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        SizedBox(width: 8),
                        Text(
                          video.formattedSize,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Quality indicator
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${video.width}x${video.height}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoPlaceholder() {
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

  // ==================== ACTION METHODS ====================

  void _showImageViewer(BuildContext context, List<PostImage> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageViewerPage(
          images: images,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _playVideo(BuildContext context, PostVideo video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(video: video),
      ),
    );
  }

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

// ==================== IMAGE VIEWER PAGE ====================

class ImageViewerPage extends StatefulWidget {
  final List<PostImage> images;
  final int initialIndex;

  const ImageViewerPage({
    Key? key,
    required this.images,
    required this.initialIndex,
  }) : super(key: key);

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download, color: Colors.white),
            onPressed: () => _downloadImage(widget.images[_currentIndex]),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final image = widget.images[index];
          return Center(
            child: Hero(
              tag: 'image_${image.publicId}',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: image.url, // Full resolution
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      color: const Color(0xFFD2B48C),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'ไม่สามารถโหลดรูปภาพได้',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _downloadImage(PostImage image) {
    // TODO: Implement image download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์ดาวน์โหลดกำลังพัฒนา'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }
}

// ==================== VIDEO PLAYER PAGE ====================

class VideoPlayerPage extends StatefulWidget {
  final PostVideo video;

  const VideoPlayerPage({Key? key, required this.video}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() async {
    try {
      _controller = VideoPlayerController.network(widget.video.url);
      await _controller.initialize();
      
      setState(() {
        _isInitialized = true;
      });
      
      _controller.play();
    } catch (e) {
      print('Error initializing video: $e');
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'วิดีโอ',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Center(
        child: _hasError
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.white, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'ไม่สามารถเล่นวิดีโอได้',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ],
              )
            : !_isInitialized
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: const Color(0xFFD2B48C),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'กำลังโหลดวิดีโอ...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  )
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _isInitialized && !_hasError
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              backgroundColor: const Color(0xFFD2B48C),
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.black,
              ),
            )
          : null,
    );
  }
}