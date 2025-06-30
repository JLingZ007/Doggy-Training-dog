// widgets/community_widgets/post_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                CircleAvatar(
                  radius: 22,
                  backgroundImage: post.authorAvatar != null
                      ? NetworkImage(post.authorAvatar!)
                      : null,
                  backgroundColor: const Color(0xFFD2B48C),
                  child: post.authorAvatar == null
                      ? Icon(Icons.person, color: Colors.white, size: 26)
                      : null,
                ),
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
                    // แสดงตัวเลือกลบเฉพาะเจ้าของโพสต์
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
          
          // Images
          if (post.imageUrls.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
              height: 250,
              child: post.imageUrls.length == 1
                  ? Image.network(
                      post.imageUrls[0],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.broken_image, size: 50),
                      ),
                    )
                  : PageView.builder(
                      itemCount: post.imageUrls.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              post.imageUrls[index],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[300],
                                child: Icon(Icons.broken_image, size: 50),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
          
          // Video
          if (post.videoUrl != null) ...[
            SizedBox(height: 12),
            Container(
              height: 200,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_circle_fill,
                      size: 64,
                      color: Colors.white,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'แตะเพื่อเล่นวิดีโอ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
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
        content: Text('ฟีเจอร์แชร์กำลังพัฒนา'),
        backgroundColor: Colors.blue[600],
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
                  content: Text('ส่งรายงานเรียบร้อยแล้ว'),
                  backgroundColor: Colors.orange[600],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
        content: Text('คุณต้องการลบโพสต์นี้หรือไม่?\nการดำเนินการนี้ไม่สามารถยกเลิกได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<CommunityProvider>();
              final success = await provider.deletePost(post.id, post.groupId);
              
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ลบโพสต์เรียบร้อยแล้ว'),
                    backgroundColor: Colors.green[600],
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ไม่สามารถลบโพสต์ได้'),
                    backgroundColor: Colors.red[600],
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('ลบ'),
          ),
        ],
      ),
    );
  }
}