import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';
import 'community_service.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CommunityService _communityService = CommunityService();

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserName => _auth.currentUser?.displayName ?? 
      _auth.currentUser?.email?.split('@').first ?? 'Unknown User';

  // ==================== POST MANAGEMENT ====================

  /// สร้างโพสต์ใหม่พร้อมอัปโหลดรูปภาพ/วิดีโอ
  Future<String?> createPost({
    required String groupId,
    required String content,
    List<XFile>? imageFiles,
    XFile? videoFile,
    PostType type = PostType.text,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Creating post in group: $groupId');

      // อัปโหลดรูปภาพไป Cloudinary (ถ้ามี)
      List<PostImage> images = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('Uploading ${imageFiles.length} images to Cloudinary...');
        
        final uploadResults = await CloudinaryService.uploadMultipleImages(
          imageFiles: imageFiles,
          folder: 'community_posts',
          customTags: {
            'type': 'post_image',
            'user_id': currentUserId!,
            'group_id': groupId,
          },
          autoOptimize: true,
          maxWidth: 1200,
          maxHeight: 1200,
          maxConcurrent: 3,
        );

        for (final result in uploadResults) {
          if (result['success'] == true) {
            images.add(PostImage(
              url: result['url'],
              publicId: result['public_id'],
              thumbnailUrl: CloudinaryService.getThumbnailUrl(
                publicId: result['public_id'],
                size: 300,
              ),
              mediumUrl: CloudinaryService.getOptimizedUrl(
                publicId: result['public_id'],
                width: 800,
                height: 600,
              ),
              width: result['width'],
              height: result['height'],
              format: result['format'],
              bytes: result['bytes'],
            ));
          } else {
            throw Exception('Failed to upload image: ${result['error']}');
          }
        }

        print('Successfully uploaded ${images.length} images');
      }

      // อัปโหลดวิดีโอไป Cloudinary (ถ้ามี)
      PostVideo? video;
      if (videoFile != null) {
        print('Uploading video to Cloudinary...');
        
        final uploadResult = await CloudinaryService.uploadVideo(
          videoFile: videoFile,
          folder: 'community_videos',
          customTags: {
            'type': 'post_video',
            'user_id': currentUserId!,
            'group_id': groupId,
          },
          autoOptimize: true,
        );

        if (uploadResult['success'] == true) {
          video = PostVideo(
            url: uploadResult['url'],
            publicId: uploadResult['public_id'],
            thumbnailUrl: uploadResult['thumbnail_url'] ?? '',
            width: uploadResult['width'] ?? 0,
            height: uploadResult['height'] ?? 0,
            format: uploadResult['format'] ?? '',
            bytes: uploadResult['bytes'] ?? 0,
            duration: uploadResult['duration'] ?? 0,
          );
          print('Successfully uploaded video');
        } else {
          throw Exception('Failed to upload video: ${uploadResult['error']}');
        }
      }

      // สร้างข้อมูลโพสต์
      final postData = {
        'groupId': groupId,
        'authorId': currentUserId!,
        'authorName': currentUserName ?? '',
        'authorAvatar': _auth.currentUser?.photoURL,
        'content': content,
        'type': type.toString().split('.').last,
        'images': images.map((img) => img.toMap()).toList(),
        'video': video?.toMap(),
        'imageCount': images.length,
        'hasVideo': video != null,
        'likedBy': <String>[],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      print('Post created with ID: ${docRef.id}');

      // อัปเดตจำนวนโพสต์ในกลุ่ม
      await _communityService.updateGroupPostCount(groupId, 1);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// อัปเดตโพสต์
  Future<bool> updatePost({
    required String postId,
    String? newContent,
    List<XFile>? newImageFiles,
    List<String>? imagesToDelete, // public_ids ของรูปที่จะลบ
    XFile? newVideoFile,
    bool removeVideo = false,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // ตรวจสอบสิทธิ์
      final postDoc = await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;
      if (postData['authorId'] != currentUserId) {
        throw Exception('No permission to update this post');
      }

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (newContent != null) {
        updateData['content'] = newContent;
      }

      // จัดการรูปภาพ
      List<PostImage> currentImages = (postData['images'] as List? ?? [])
          .map((img) => PostImage.fromMap(img as Map<String, dynamic>))
          .toList();

      // ลบรูปที่ไม่ต้องการ
      if (imagesToDelete != null && imagesToDelete.isNotEmpty) {
        for (String publicIdToDelete in imagesToDelete) {
          await CloudinaryService.deleteImage(publicIdToDelete);
          currentImages.removeWhere((img) => img.publicId == publicIdToDelete);
        }
      }

      // เพิ่มรูปใหม่
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        final uploadResults = await CloudinaryService.uploadMultipleImages(
          imageFiles: newImageFiles,
          folder: 'community_posts',
          customTags: {
            'type': 'post_image',
            'user_id': currentUserId!,
            'post_id': postId,
          },
          autoOptimize: true,
          maxWidth: 1200,
          maxHeight: 1200,
        );

        for (final result in uploadResults) {
          if (result['success'] == true) {
            currentImages.add(PostImage(
              url: result['url'],
              publicId: result['public_id'],
              thumbnailUrl: CloudinaryService.getThumbnailUrl(
                publicId: result['public_id'],
                size: 300,
              ),
              mediumUrl: CloudinaryService.getOptimizedUrl(
                publicId: result['public_id'],
                width: 800,
                height: 600,
              ),
              width: result['width'],
              height: result['height'],
              format: result['format'],
              bytes: result['bytes'],
            ));
          }
        }
      }

      updateData['images'] = currentImages.map((img) => img.toMap()).toList();
      updateData['imageCount'] = currentImages.length;

      // จัดการวิดีโอ
      PostVideo? currentVideo;
      if (postData['video'] != null) {
        currentVideo = PostVideo.fromMap(postData['video'] as Map<String, dynamic>);
      }

      if (removeVideo && currentVideo != null) {
        // ลบวิดีโอเก่า
        await CloudinaryService.deleteVideo(currentVideo.publicId);
        updateData['video'] = null;
        updateData['hasVideo'] = false;
      } else if (newVideoFile != null) {
        // ลบวิดีโอเก่า (ถ้ามี)
        if (currentVideo != null) {
          await CloudinaryService.deleteVideo(currentVideo.publicId);
        }

        // อัปโหลดวิดีโอใหม่
        final uploadResult = await CloudinaryService.uploadVideo(
          videoFile: newVideoFile,
          folder: 'community_videos',
          customTags: {
            'type': 'post_video',
            'user_id': currentUserId!,
            'post_id': postId,
          },
          autoOptimize: true,
        );

        if (uploadResult['success'] == true) {
          final newVideo = PostVideo(
            url: uploadResult['url'],
            publicId: uploadResult['public_id'],
            thumbnailUrl: uploadResult['thumbnail_url'] ?? '',
            width: uploadResult['width'] ?? 0,
            height: uploadResult['height'] ?? 0,
            format: uploadResult['format'] ?? '',
            bytes: uploadResult['bytes'] ?? 0,
            duration: uploadResult['duration'] ?? 0,
          );

          updateData['video'] = newVideo.toMap();
          updateData['hasVideo'] = true;
        }
      }

      // บันทึกการเปลี่ยนแปลง
      await _firestore.collection('community_posts').doc(postId).update(updateData);
      print('Post $postId updated successfully');

      return true;
    } catch (e) {
      print('Error updating post: $e');
      return false;
    }
  }

  /// ลบโพสต์
  Future<bool> deletePost(String postId, String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final postDoc = await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) {
        throw Exception('Post not found');
      }

      final postData = postDoc.data()!;

      // ตรวจสอบสิทธิ์ (เจ้าของโพสต์หรือ admin ของกลุ่ม)
      bool canDelete = postData['authorId'] == currentUserId;
      
      if (!canDelete) {
        final memberDoc = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('members')
            .doc(currentUserId)
            .get();
        
        canDelete = memberDoc.exists && memberDoc.data()?['role'] == 'admin';
      }

      if (!canDelete) {
        throw Exception('No permission to delete this post');
      }

      // ลบรูปภาพและวิดีโอใน Cloudinary
      final images = (postData['images'] as List? ?? [])
          .map((img) => PostImage.fromMap(img as Map<String, dynamic>))
          .toList();

      for (final image in images) {
        await CloudinaryService.deleteImage(image.publicId);
      }

      if (postData['video'] != null) {
        final video = PostVideo.fromMap(postData['video'] as Map<String, dynamic>);
        await CloudinaryService.deleteVideo(video.publicId);
      }

      print('Deleted ${images.length} images and ${postData['video'] != null ? 1 : 0} video from Cloudinary');

      // ลบโพสต์
      await _firestore.collection('community_posts').doc(postId).delete();
      print('Post $postId deleted successfully');

      // อัปเดตจำนวนโพสต์ในกลุ่ม
      await _communityService.updateGroupPostCount(groupId, -1);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  /// ดึงโพสต์ในกลุ่ม
  Stream<List<CommunityPost>> getGroupPosts({
    required String groupId,
    int limit = 20,
  }) {
    print('Getting posts for group: $groupId');
    
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((error) {
          print('Error in getGroupPosts stream: $error');
        })
        .map((snapshot) {
          print('Group $groupId has ${snapshot.docs.length} posts');
          
          return snapshot.docs.map((doc) {
            try {
              return CommunityPost.fromFirestore(doc);
            } catch (e) {
              print('Error parsing post ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        });
  }

  /// ดึงโพสต์เดียว
  Future<CommunityPost?> getPostById(String postId) async {
    try {
      final doc = await _firestore.collection('community_posts').doc(postId).get();
      
      if (doc.exists) {
        return CommunityPost.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      print('Error getting post: $e');
      return null;
    }
  }

  /// กดไลค์/ยกเลิกไลค์โพสต์
  Future<bool> togglePostLike(String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('community_posts').doc(postId);
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          throw Exception('Post not found');
        }

        final postData = postSnapshot.data()!;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);
        
        if (likedBy.contains(currentUserId)) {
          likedBy.remove(currentUserId);
        } else {
          likedBy.add(currentUserId!);
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error toggling post like: $e');
      return false;
    }
  }

  // ==================== COMMENT MANAGEMENT ====================

  /// เพิ่มความคิดเห็น
  Future<String?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final commentData = {
        'postId': postId,
        'authorId': currentUserId!,
        'authorName': currentUserName ?? '',
        'authorAvatar': _auth.currentUser?.photoURL,
        'content': content,
        'parentCommentId': parentCommentId,
        'likedBy': <String>[],
        'likeCount': 0,
        'replyCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('post_comments').add(commentData);
      print('Comment created with ID: ${docRef.id}');

      // อัปเดตจำนวนความคิดเห็นในโพสต์
      await _updatePostCommentCount(postId, 1);

      // ถ้าเป็น reply ให้อัปเดต replyCount ของ parent comment
      if (parentCommentId != null) {
        await _updateCommentReplyCount(parentCommentId, 1);
      }

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// ลบความคิดเห็น
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
      if (!commentDoc.exists) {
        throw Exception('Comment not found');
      }

      final commentData = commentDoc.data()!;
      
      // ตรวจสอบสิทธิ์
      if (commentData['authorId'] != currentUserId) {
        throw Exception('No permission to delete this comment');
      }

      // ลบ replies ทั้งหมด
      final repliesSnapshot = await _firestore
          .collection('post_comments')
          .where('parentCommentId', isEqualTo: commentId)
          .get();

      final batch = _firestore.batch();
      for (final replyDoc in repliesSnapshot.docs) {
        batch.delete(replyDoc.reference);
      }

      // ลบ comment หลัก
      batch.delete(_firestore.collection('post_comments').doc(commentId));
      
      await batch.commit();

      // อัปเดตจำนวนความคิดเห็น
      final totalDeleted = repliesSnapshot.docs.length + 1;
      await _updatePostCommentCount(postId, -totalDeleted);

      // ถ้าเป็น reply ให้อัปเดต parent comment
      if (commentData['parentCommentId'] != null) {
        await _updateCommentReplyCount(commentData['parentCommentId'], -1);
      }

      print('Comment $commentId and ${repliesSnapshot.docs.length} replies deleted');
      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  /// กดไลค์/ยกเลิกไลค์ความคิดเห็น
  Future<bool> toggleCommentLike(String commentId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      return await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentSnapshot = await transaction.get(commentRef);

        if (!commentSnapshot.exists) {
          throw Exception('Comment not found');
        }

        final commentData = commentSnapshot.data()!;
        final likedBy = List<String>.from(commentData['likedBy'] ?? []);
        
        if (likedBy.contains(currentUserId)) {
          likedBy.remove(currentUserId);
        } else {
          likedBy.add(currentUserId!);
        }

        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  /// ดึงความคิดเห็นของโพสต์
  Stream<List<PostComment>> getPostComments(String postId) {
    return _firestore
        .collection('post_comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList());
  }

  /// ดึง replies ของความคิดเห็น
  Stream<List<PostComment>> getCommentReplies(String commentId) {
    return _firestore
        .collection('post_comments')
        .where('parentCommentId', isEqualTo: commentId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostComment.fromFirestore(doc))
            .toList());
  }

  // ==================== HELPER METHODS ====================

  /// อัปเดตจำนวนความคิดเห็นในโพสต์
  Future<void> _updatePostCommentCount(String postId, int change) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('community_posts').doc(postId);
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) return;

        final postData = postSnapshot.data()!;
        final currentCount = postData['commentCount'] ?? 0;
        final newCount = (currentCount + change).clamp(0, double.infinity).toInt();

        transaction.update(postRef, {
          'commentCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating post comment count: $e');
    }
  }

  /// อัปเดตจำนวน replies ในความคิดเห็น
  Future<void> _updateCommentReplyCount(String commentId, int change) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentSnapshot = await transaction.get(commentRef);

        if (!commentSnapshot.exists) return;

        final commentData = commentSnapshot.data()!;
        final currentCount = commentData['replyCount'] ?? 0;
        final newCount = (currentCount + change).clamp(0, double.infinity).toInt();

        transaction.update(commentRef, {
          'replyCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating comment reply count: $e');
    }
  }
}

// ==================== MODELS ====================

enum PostType { text, image, video, mixed }

/// Model สำหรับโพสต์
class CommunityPost {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final PostType type;
  final List<PostImage> images;
  final PostVideo? video;
  final List<String> likedBy;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.type,
    required this.images,
    this.video,
    required this.likedBy,
    required this.commentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommunityPost(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      type: PostType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => PostType.text,
      ),
      images: (data['images'] as List? ?? [])
          .map((img) => PostImage.fromMap(img as Map<String, dynamic>))
          .toList(),
      video: data['video'] != null 
          ? PostVideo.fromMap(data['video'] as Map<String, dynamic>)
          : null,
      likedBy: List<String>.from(data['likedBy'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  int get likeCount => likedBy.length;
  bool get hasImages => images.isNotEmpty;
  bool get hasVideo => video != null;
  
  bool isLikedBy(String userId) => likedBy.contains(userId);
}

/// Model สำหรับรูปภาพในโพสต์
class PostImage {
  final String url;           // Full size URL
  final String publicId;      // Cloudinary public_id
  final String thumbnailUrl;  // Thumbnail URL
  final String mediumUrl;     // Medium size URL
  final int width;
  final int height;
  final String format;
  final int bytes;

  PostImage({
    required this.url,
    required this.publicId,
    required this.thumbnailUrl,
    required this.mediumUrl,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
  });

  factory PostImage.fromMap(Map<String, dynamic> map) {
    return PostImage(
      url: map['url'] ?? '',
      publicId: map['publicId'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      mediumUrl: map['mediumUrl'] ?? '',
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      format: map['format'] ?? '',
      bytes: map['bytes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'publicId': publicId,
      'thumbnailUrl': thumbnailUrl,
      'mediumUrl': mediumUrl,
      'width': width,
      'height': height,
      'format': format,
      'bytes': bytes,
    };
  }

  double get aspectRatio => width / height;
  String get formattedSize {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

/// Model สำหรับวิดีโอในโพสต์
class PostVideo {
  final String url;
  final String publicId;
  final String thumbnailUrl;
  final int width;
  final int height;
  final String format;
  final int bytes;
  final int duration; // ในหน่วยวินาที

  PostVideo({
    required this.url,
    required this.publicId,
    required this.thumbnailUrl,
    required this.width,
    required this.height,
    required this.format,
    required this.bytes,
    required this.duration,
  });

  factory PostVideo.fromMap(Map<String, dynamic> map) {
    return PostVideo(
      url: map['url'] ?? '',
      publicId: map['publicId'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      width: map['width'] ?? 0,
      height: map['height'] ?? 0,
      format: map['format'] ?? '',
      bytes: map['bytes'] ?? 0,
      duration: map['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'publicId': publicId,
      'thumbnailUrl': thumbnailUrl,
      'width': width,
      'height': height,
      'format': format,
      'bytes': bytes,
      'duration': duration,
    };
  }

  double get aspectRatio => width / height;
  String get formattedSize {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Model สำหรับความคิดเห็น
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? parentCommentId;
  final List<String> likedBy;
  final int replyCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.parentCommentId,
    required this.likedBy,
    required this.replyCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      content: data['content'] ?? '',
      parentCommentId: data['parentCommentId'],
      likedBy: List<String>.from(data['likedBy'] ?? []),
      replyCount: data['replyCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  int get likeCount => likedBy.length;
  bool get isReply => parentCommentId != null;
  bool get hasReplies => replyCount > 0;
  
  bool isLikedBy(String userId) => likedBy.contains(userId);
}