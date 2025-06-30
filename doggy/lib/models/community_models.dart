// models/community_models.dart
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
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== GROUP MEMBER ====================
class GroupMember {
  final String userId;
  final String userName;
  final String userEmail;
  final String? userAvatar;
  final String role; // 'admin', 'member'
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userAvatar,
    required this.role,
    required this.joinedAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userAvatar': userAvatar,
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
      role: data['role'] ?? 'member',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

// ==================== COMMUNITY POST ====================
class CommunityPost {
  final String id;
  final String groupId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final List<String> imageUrls;
  final String? videoUrl;
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
    required this.content,
    this.imageUrls = const [],
    this.videoUrl,
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
      'content': content,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
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
      content: data['content'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      videoUrl: data['videoUrl'],
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
    String? content,
    List<String>? imageUrls,
    String? videoUrl,
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
      content: content ?? this.content,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrl: videoUrl ?? this.videoUrl,
      type: type ?? this.type,
      likedBy: likedBy ?? this.likedBy,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// ==================== POST COMMENT ====================
class PostComment {
  final String id;
  final String postId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
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
      content: content ?? this.content,
      likedBy: likedBy ?? this.likedBy,
      likeCount: likeCount ?? this.likeCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}