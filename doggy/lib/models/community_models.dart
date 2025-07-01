// models/community_models.dart - อัพเดทจาก model เดิม
import 'package:cloud_firestore/cloud_firestore.dart';

enum PostType { text, image, video, mixed }

// ==================== COMMUNITY GROUP ====================
class CommunityGroup {
  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final List<String> memberIds;
  final int memberCount;
  final int postCount;
  final bool isPublic;
  final String? coverImage;
  final String? coverImageBase64; 
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.description,
    this.tags = const [],
    this.memberIds = const [],
    this.memberCount = 0,
    this.postCount = 0,
    this.isPublic = true,
    this.coverImage,
    this.coverImageBase64, 
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'tags': tags,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'postCount': postCount,
      'isPublic': isPublic,
      'coverImage': coverImage, 
      'coverImageBase64': coverImageBase64,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

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
      coverImage: data['coverImage'],
      coverImageBase64: data['coverImageBase64'], 
      createdBy: data['createdBy'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  CommunityGroup copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? tags,
    List<String>? memberIds,
    int? memberCount,
    int? postCount,
    bool? isPublic,
    String? coverImage,
    String? coverImageBase64, 
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      coverImage: coverImage ?? this.coverImage,
      coverImageBase64: coverImageBase64 ?? this.coverImageBase64,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Helper method ใหม่: ดึงรูป cover (Base64 หรือ URL)
  String? get displayCoverImage => coverImageBase64 ?? coverImage;
}

// ==================== GROUP MEMBER ====================
class GroupMember {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String? userAvatarBase64;
  final String role; // 'admin', 'member'
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    this.userAvatarBase64, 
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
      'userAvatarBase64': userAvatarBase64, 
      'role': role,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  factory GroupMember.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMember(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userAvatar: data['userAvatar'],
      userAvatarBase64: data['userAvatarBase64'],
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // ✅ Helper method ใหม่: ดึงอวตาร์ (Base64 หรือ URL)
  String? get displayAvatar => userAvatarBase64 ?? userAvatar;
}

// ==================== COMMUNITY POST ====================
class CommunityPost {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorAvatarBase64;
  final String content;
  final List<String> imageUrls;
  final List<String> imageBase64s; 
  final String? videoUrl;
  final String? videoBase64; 
  final PostType type;
  final List<String> likedBy;
  final int likeCount;
  final int commentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CommunityPost({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorAvatarBase64,
    required this.content,
    this.imageUrls = const [],
    this.imageBase64s = const [], 
    this.videoUrl,
    this.videoBase64, 
    this.type = PostType.text,
    this.likedBy = const [],
    this.likeCount = 0,
    this.commentCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'groupId': groupId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorAvatarBase64': authorAvatarBase64,
      'content': content,
      'imageUrls': imageUrls,
      'imageBase64s': imageBase64s, 
      'videoUrl': videoUrl,
      'videoBase64': videoBase64, 
      'type': type.toString().split('.').last,
      'likedBy': likedBy,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityPost(
      id: doc.id,
      groupId: data['groupId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      authorAvatarBase64: data['authorAvatarBase64'],
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      imageBase64s: List<String>.from(data['imageBase64s'] ?? []), 
      videoUrl: data['videoUrl'],
      videoBase64: data['videoBase64'], 
      type: _parsePostType(data['type']),
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static PostType _parsePostType(String? typeString) {
    switch (typeString) {
      case 'image':
        return PostType.image;
      case 'video':
        return PostType.video;
      case 'mixed':
        return PostType.mixed;
      default:
        return PostType.text;
    }
  }

  CommunityPost copyWith({
    String? id,
    String? groupId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorAvatarBase64,
    String? content,
    List<String>? imageUrls,
    List<String>? imageBase64s,
    String? videoUrl,
    String? videoBase64,
    PostType? type,
    List<String>? likedBy,
    int? likeCount,
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
      authorAvatarBase64: authorAvatarBase64 ?? this.authorAvatarBase64,
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      imageBase64s: imageBase64s ?? this.imageBase64s,
      videoUrl: videoUrl ?? this.videoUrl,
      videoBase64: videoBase64 ?? this.videoBase64, 
      type: type ?? this.type,
      likedBy: likedBy ?? this.likedBy,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ✅ Helper methods ใหม่
  
  /// ดึงรูปภาพทั้งหมด (รวม URL และ Base64)
  List<String> get allImages {
    List<String> allImages = [];
    allImages.addAll(imageUrls);
    allImages.addAll(imageBase64s);
    return allImages;
  }

  /// ตรวจสอบว่ามีรูปภาพหรือไม่
  bool get hasImages => imageUrls.isNotEmpty || imageBase64s.isNotEmpty;

  /// ตรวจสอบว่ามีวิดีโอหรือไม่
  bool get hasVideo => videoUrl != null || videoBase64 != null;

  /// ดึงอวตาร์ผู้เขียน (Base64 หรือ URL)
  String? get displayAuthorAvatar => authorAvatarBase64 ?? authorAvatar;

  /// ดึงวิดีโอ (Base64 หรือ URL) 
  String? get displayVideo => videoBase64 ?? videoUrl;

  /// ตรวจสอบว่าเป็น Base64 หรือไม่
  bool isBase64String(String str) {
    return str.startsWith('data:') && str.contains('base64,');
  }
}

// ==================== POST COMMENT ====================
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? authorAvatarBase64;
  final String content;
  final List<String> likedBy;
  final int likeCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? parentCommentId; // สำหรับ reply

  PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.authorAvatarBase64,
    required this.content,
    this.likedBy = const [],
    this.likeCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorAvatarBase64': authorAvatarBase64,
      'content': content,
      'likedBy': likedBy,
      'likeCount': likeCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'parentCommentId': parentCommentId,
    };
  }

  factory PostComment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PostComment(
      id: doc.id,
      postId: data['postId'] ?? '',
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? '',
      authorAvatar: data['authorAvatar'],
      authorAvatarBase64: data['authorAvatarBase64'],
      content: data['content'] ?? '',
      likedBy: List<String>.from(data['likedBy'] ?? []),
      likeCount: data['likeCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentCommentId: data['parentCommentId'],
    );
  }

  PostComment copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    String? authorAvatarBase64,
    String? content,
    List<String>? likedBy,
    int? likeCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? parentCommentId,
  }) {
    return PostComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorAvatarBase64: authorAvatarBase64 ?? this.authorAvatarBase64,
      content: content ?? this.content,
      likedBy: likedBy ?? this.likedBy,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }

  //  Helper method ใหม่: ดึงอวตาร์ (Base64 หรือ URL)
  String? get displayAvatar => authorAvatarBase64 ?? authorAvatar;
}