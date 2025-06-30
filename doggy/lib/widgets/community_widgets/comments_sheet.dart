import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';

class CommentsSheet extends StatefulWidget {
  final CommunityPost post;

  const CommentsSheet({Key? key, required this.post}) : super(key: key);

  @override
  _CommentsSheetState createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPostComments(widget.post.id);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.comment, color: const Color(0xFF8B4513), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'ความคิดเห็น',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B4513),
                      ),
                    ),
                    Spacer(),
                    Consumer<CommunityProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          '${provider.currentPostComments.length} ความคิดเห็น',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              Divider(height: 32),
              
              // Comments list
              Expanded(
                child: Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoadingComments) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFD2B48C),
                        ),
                      );
                    }

                    if (provider.currentPostComments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ยังไม่มีความคิดเห็น',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'เป็นคนแรกที่แสดงความคิดเห็น!',
                              style: TextStyle(
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: provider.currentPostComments.length,
                      itemBuilder: (context, index) {
                        final comment = provider.currentPostComments[index];
                        return _buildCommentItem(comment);
                      },
                    );
                  },
                ),
              ),
              
              // Comment input
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFD2B48C),
                        child: Icon(Icons.person, color: Colors.white, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          decoration: InputDecoration(
                            hintText: 'เขียนความคิดเห็น...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      SizedBox(width: 8),
                      Consumer<CommunityProvider>(
                        builder: (context, provider, child) {
                          return IconButton(
                            onPressed: provider.isLoading ? null : _addComment,
                            icon: provider.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: const Color(0xFFD2B48C),
                                    ),
                                  )
                                : Icon(
                                    Icons.send,
                                    color: const Color(0xFF8B4513),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommentItem(PostComment comment) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: comment.authorAvatar != null
                ? NetworkImage(comment.authorAvatar!)
                : null,
            backgroundColor: const Color(0xFFD2B48C),
            child: comment.authorAvatar == null
                ? Icon(Icons.person, color: Colors.white, size: 18)
                : null,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        comment.authorName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF8B4513),
                        ),
                      ),
                      Spacer(),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    comment.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Consumer<CommunityProvider>(
                        builder: (context, provider, child) {
                          final isLiked = comment.likedBy.contains(
                            provider.communityService.currentUserId,
                          );
                          
                          return InkWell(
                            onTap: () => provider.toggleCommentLike(comment.id),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isLiked ? Icons.favorite : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.grey[500],
                                    size: 16,
                                  ),
                                  if (comment.likeCount > 0) ...[
                                    SizedBox(width: 4),
                                    Text(
                                      '${comment.likeCount}',
                                      style: TextStyle(
                                        color: isLiked ? Colors.red : Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 16),
                      InkWell(
                        onTap: () {
                          // TODO: Implement reply functionality
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'ตอบกลับ',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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

  void _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final provider = context.read<CommunityProvider>();
    final success = await provider.addComment(
      postId: widget.post.id,
      content: content,
    );

    if (success) {
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('เพิ่มความคิดเห็นเรียบร้อยแล้ว'),
          backgroundColor: Colors.green[600],
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'ไม่สามารถเพิ่มความคิดเห็นได้'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}