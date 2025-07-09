// models/community_models.dart - Fixed version without duplicate extensions
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

// ==================== ENUMS ====================

enum PostType { text, image, video, mixed }

// ==================== GROUP MODELS ====================

class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final List<String> memberIds;
  final int memberCount;
  final int postCount;
  final bool isPublic;
  final String? coverImageUrl;      // Cloudinary URL
  final String? coverImagePublicId; // Cloudinary public_id
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // สำหรับการสร้างกลุ่มใหม่
  final XFile? coverImageFile;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.tags,
    required this.memberIds,
    required this.memberCount,
    required this.postCount,
    required this.isPublic,
    this.coverImageUrl,
    this.coverImagePublicId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.coverImageFile,
  });

  factory CommunityGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CommunityGroup(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      memberIds: List<String>.from(data['memberIds'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      postCount: data['postCount'] ?? 0,
      isPublic: data['isPublic'] ?? true,
      coverImageUrl: data['coverImageUrl'],
      coverImagePublicId: data['coverImagePublicId'],
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'tags': tags,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'postCount': postCount,
      'isPublic': isPublic,
      'coverImageUrl': coverImageUrl,
      'coverImagePublicId': coverImagePublicId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  CommunityGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
    List<String>? memberIds,
    int? memberCount,
    int? postCount,
    bool? isPublic,
    String? coverImageUrl,
    String? coverImagePublicId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    XFile? coverImageFile,
  }) {
    return CommunityGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      postCount: postCount ?? this.postCount,
      isPublic: isPublic ?? this.isPublic,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      coverImagePublicId: coverImagePublicId ?? this.coverImagePublicId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageFile: coverImageFile ?? this.coverImageFile,
    );
  }

  // Helper getters
  String get coverImage => coverImageUrl ?? '';
  bool get hasCoverImage => coverImageUrl != null && coverImageUrl!.isNotEmpty;
}

class GroupMember {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String? userAvatar;
  final String role; // admin, member
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GroupMember(
      id: doc.id,
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userName: data['userName'] ?? '',
      userAvatar: data['userAvatar'],
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isAdmin => role == 'admin';
}

// ==================== POST MODELS ====================

class PostImage {
  final String url;           // Full size URL from Cloudinary
  final String publicId;      // Cloudinary public_id สำหรับการลบ
  final String thumbnailUrl;  // Thumbnail URL (optimized)
  final String mediumUrl;     // Medium size URL (optimized)
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

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1.0;
  
  String get formattedSize {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class PostVideo {
  final String url;           // Video URL from Cloudinary
  final String publicId;      // Cloudinary public_id สำหรับการลบ
  final String thumbnailUrl;  // Video thumbnail URL
  final int width;
  final int height;
  final String format;
  final int bytes;
  final int duration;         // ในหน่วยวินาที

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

  double get aspectRatio => width > 0 && height > 0 ? width / height : 1.0;
  
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

class CommunityPost {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final PostType type;
  final List<PostImage> images;    // Cloudinary images
  final PostVideo? video;          // Cloudinary video
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

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'type': type.toString().split('.').last,
      'images': images.map((img) => img.toMap()).toList(),
      'video': video?.toMap(),
      'imageCount': images.length,
      'hasVideo': video != null,
      'likedBy': likedBy,
      'likeCount': likedBy.length,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  // Helper getters
  int get likeCount => likedBy.length;
  bool get hasImages => images.isNotEmpty;
  bool get hasVideo => video != null;
  bool get hasMedia => hasImages || hasVideo;
  
  bool isLikedBy(String userId) => likedBy.contains(userId);

  CommunityPost copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    PostType? type,
    List<PostImage>? images,
    PostVideo? video,
    List<String>? likedBy,
    int? commentCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommunityPost(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      images: images ?? this.images,
      video: video ?? this.video,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== COMMENT MODELS ====================

class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? parentCommentId;  // สำหรับ reply
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

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'parentCommentId': parentCommentId,
      'likedBy': likedBy,
      'likeCount': likedBy.length,
      'replyCount': replyCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper getters
  int get likeCount => likedBy.length;
  bool get isReply => parentCommentId != null;
  bool get hasReplies => replyCount > 0;
  
  bool isLikedBy(String userId) => likedBy.contains(userId);

  PostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? content,
    String? parentCommentId,
    List<String>? likedBy,
    int? replyCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      content: content ?? this.content,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      likedBy: likedBy ?? this.likedBy,
      replyCount: replyCount ?? this.replyCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== DTO CLASSES สำหรับการสร้างข้อมูลใหม่ ====================

class CreateGroupDto {
  final String name;
  final String description;
  final List<String> tags;
  final bool isPublic;
  final XFile? coverImageFile;

  CreateGroupDto({
    required this.name,
    required this.description,
    required this.tags,
    required this.isPublic,
    this.coverImageFile,
  });
}

class CreatePostDto {
  final String groupId;
  final String content;
  final List<XFile>? imageFiles;
  final XFile? videoFile;
  final PostType type;

  CreatePostDto({
    required this.groupId,
    required this.content,
    this.imageFiles,
    this.videoFile,
    this.type = PostType.text,
  });

  bool get hasImages => imageFiles != null && imageFiles!.isNotEmpty;
  bool get hasVideo => videoFile != null;
  bool get hasMedia => hasImages || hasVideo;

  PostType get inferredType {
    if (hasVideo && hasImages) return PostType.mixed;
    if (hasVideo) return PostType.video;
    if (hasImages) return PostType.image;
    return PostType.text;
  }
}

class CreateCommentDto {
  final String postId;
  final String content;
  final String? parentCommentId;

  CreateCommentDto({
    required this.postId,
    required this.content,
    this.parentCommentId,
  });

  bool get isReply => parentCommentId != null;
}

// ==================== UTILITY EXTENSIONS ====================

extension DateTimeExtension on DateTime {
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} นาทีที่แล้ว';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ชั่วโมงที่แล้ว';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} วันที่แล้ว';
    } else {
      return '${day}/${month}/${year}';
    }
  }

  String get formattedDate {
    return '${day}/${month}/${year} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

// ==================== HELPER FUNCTIONS ====================

String getPostTypeDisplayName(PostType type) {
  switch (type) {
    case PostType.text:
      return 'ข้อความ';
    case PostType.image:
      return 'รูปภาพ';
    case PostType.video:
      return 'วิดีโอ';
    case PostType.mixed:
      return 'รูปภาพและวิดีโอ';
  }
}

IconData getPostTypeIcon(PostType type) {
  switch (type) {
    case PostType.text:
      return Icons.text_fields;
    case PostType.image:
      return Icons.image;
    case PostType.video:
      return Icons.videocam;
    case PostType.mixed:
      return Icons.perm_media;
  }
}