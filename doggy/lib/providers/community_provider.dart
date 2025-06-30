// providers/community_provider.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/community_models.dart';
import '../services/community_service.dart';
import 'dart:io';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();
  
  // Groups
  List<CommunityGroup> _allGroups = [];
  List<CommunityGroup> _userGroups = [];
  
  // Posts
  List<CommunityPost> _currentGroupPosts = [];
  
  // Comments
  List<PostComment> _currentPostComments = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingPosts = false;
  bool _isLoadingComments = false;
  
  // Error handling
  String? _error;

  // Streams subscriptions สำหรับ Real-time
  StreamSubscription? _allGroupsSubscription;
  StreamSubscription? _userGroupsSubscription;
  StreamSubscription? _postsSubscription;
  StreamSubscription? _commentsSubscription;

  // Getters
  List<CommunityGroup> get allGroups => _allGroups;
  List<CommunityGroup> get userGroups => _userGroups;
  List<CommunityPost> get currentGroupPosts => _currentGroupPosts;
  List<PostComment> get currentPostComments => _currentPostComments;
  bool get isLoading => _isLoading;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingComments => _isLoadingComments;
  String? get error => _error;
  CommunityService get communityService => _communityService;

  @override
  void dispose() {
    // ยกเลิก subscriptions ทั้งหมด
    _allGroupsSubscription?.cancel();
    _userGroupsSubscription?.cancel();
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }

  // ==================== GROUP METHODS ====================

  // โหลดกลุ่มทั้งหมด - Real-time
  void loadAllGroups() {
    _allGroupsSubscription?.cancel();
    
    // แสดง loading เฉพาะเมื่อไม่มีข้อมูล
    if (_allGroups.isEmpty) {
      _setLoading(true);
    }
    
    _allGroupsSubscription = _communityService.getAllGroups().listen(
      (groups) {
        _allGroups = groups;
        _setLoading(false);
        _clearError();
      },
      onError: (error) {
        _setError('ไม่สามารถโหลดกลุ่มได้: $error');
        _setLoading(false);
      },
    );
  }

  // โหลดกลุ่มของผู้ใช้ - Real-time
  void loadUserGroups() {
    _userGroupsSubscription?.cancel();
    
    // แสดง loading เฉพาะเมื่อไม่มีข้อมูล
    if (_userGroups.isEmpty) {
      _setLoading(true);
    }
    
    _userGroupsSubscription = _communityService.getUserGroups().listen(
      (groups) {
        _userGroups = groups;
        _setLoading(false);
        _clearError();
      },
      onError: (error) {
        _setError('ไม่สามารถโหลดกลุ่มของคุณได้: $error');
        _setLoading(false);
      },
    );
  }

  // สร้างกลุ่มใหม่
  Future<bool> createGroup(CommunityGroup group) async {
    _setLoading(true);
    try {
      final groupId = await _communityService.createGroup(group);
      _setLoading(false);
      
      if (groupId != null) {
        _clearError();
        // ไม่ต้องโหลดใหม่ เพราะ Stream จะอัพเดทอัตโนมัติ
        return true;
      }
      
      _setError('ไม่สามารถสร้างกลุ่มได้');
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('ไม่สามารถสร้างกลุ่มได้: $e');
      return false;
    }
  }

  // ค้นหากลุ่ม
  Future<List<CommunityGroup>> searchGroups(String query) async {
    try {
      _clearError();
      return await _communityService.searchGroups(query);
    } catch (e) {
      _setError('ไม่สามารถค้นหากลุ่มได้: $e');
      return [];
    }
  }

  // เข้าร่วมกลุ่ม
  Future<bool> joinGroup(String groupId) async {
    try {
      _clearError();
      final success = await _communityService.joinGroup(groupId);
      
      if (!success) {
        _setError('ไม่สามารถเข้าร่วมกลุ่มได้');
      }
      
      // Stream จะอัพเดทอัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถเข้าร่วมกลุ่มได้: $e');
      return false;
    }
  }

  // ออกจากกลุ่ม
  Future<bool> leaveGroup(String groupId) async {
    try {
      _clearError();
      final success = await _communityService.leaveGroup(groupId);
      
      if (!success) {
        _setError('ไม่สามารถออกจากกลุ่มได้');
      }
      
      // Stream จะอัพเดทอัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถออกจากกลุ่มได้: $e');
      return false;
    }
  }

  // ดึงสมาชิกในกลุ่ม - Real-time
  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _communityService.getGroupMembers(groupId);
  }

  // ==================== POST METHODS ====================

  // โหลดโพสต์ในกลุ่ม - Real-time
  void loadGroupPosts(String groupId) {
    _postsSubscription?.cancel();
    _setLoadingPosts(true);
    
    _postsSubscription = _communityService.getGroupPosts(groupId).listen(
      (posts) {
        _currentGroupPosts = posts;
        _setLoadingPosts(false);
        _clearError();
      },
      onError: (error) {
        _setError('ไม่สามารถโหลดโพสต์ได้: $error');
        _setLoadingPosts(false);
      },
    );
  }

  // สร้างโพสต์ใหม่
  Future<bool> createPost({
    required String groupId,
    required String content,
    List<File>? imageFiles,
    File? videoFile,
  }) async {
    _setLoading(true);
    try {
      // อัพโหลดรูปภาพ
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        for (File imageFile in imageFiles) {
          final url = await _communityService.uploadImage(imageFile, 'community_posts');
          if (url != null) {
            imageUrls.add(url);
          }
        }
      }

      // อัพโหลดวิดีโอ
      String? videoUrl;
      if (videoFile != null) {
        videoUrl = await _communityService.uploadVideo(videoFile, 'community_posts');
      }

      // กำหนดประเภทโพสต์
      PostType postType = PostType.text;
      if (imageUrls.isNotEmpty && videoUrl != null) {
        postType = PostType.mixed;
      } else if (imageUrls.isNotEmpty) {
        postType = PostType.image;
      } else if (videoUrl != null) {
        postType = PostType.video;
      }

      // สร้างโพสต์
      final post = CommunityPost(
        id: '',
        groupId: groupId,
        authorId: '', // จะถูกกำหนดใน service
        authorName: '', // จะถูกกำหนดใน service
        authorAvatar: null, // จะถูกกำหนดใน service
        content: content,
        imageUrls: imageUrls,
        videoUrl: videoUrl,
        type: postType,
        likedBy: [],
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(), // จะถูก override ใน service
        updatedAt: DateTime.now(), // จะถูก override ใน service
      );

      final postId = await _communityService.createPost(post);
      _setLoading(false);
      
      if (postId != null) {
        _clearError();
        // Stream จะอัพเดทอัตโนมัติ
        return true;
      }
      
      _setError('ไม่สามารถสร้างโพสต์ได้');
      return false;
    } catch (e) {
      _setLoading(false);
      _setError('ไม่สามารถสร้างโพสต์ได้: $e');
      return false;
    }
  }

  // ลบโพสต์
  Future<bool> deletePost(String postId, String groupId) async {
    try {
      _clearError();
      final success = await _communityService.deletePost(postId, groupId);
      
      if (!success) {
        _setError('ไม่สามารถลบโพสต์ได้');
      }
      
      // Stream จะอัพเดทอัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถลบโพสต์ได้: $e');
      return false;
    }
  }

  // กดไลค์โพสต์ - แก้ไขเพื่อ Real-time
  Future<bool> togglePostLike(String postId) async {
    try {
      _clearError();
      final success = await _communityService.togglePostLike(postId);
      
      if (!success) {
        _setError('ไม่สามารถกดไลค์ได้');
      }
      
      // Stream จะอัพเดท like count อัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถกดไลค์ได้: $e');
      return false;
    }
  }

  // ==================== COMMENT METHODS ====================

  // โหลดคอมเมนต์ของโพสต์ - Real-time
  void loadPostComments(String postId) {
    _commentsSubscription?.cancel();
    _setLoadingComments(true);
    
    _commentsSubscription = _communityService.getPostComments(postId).listen(
      (comments) {
        _currentPostComments = comments;
        _setLoadingComments(false);
        _clearError();
      },
      onError: (error) {
        _setError('ไม่สามารถโหลดคอมเมนต์ได้: $error');
        _setLoadingComments(false);
      },
    );
  }

  // เพิ่มคอมเมนต์
  Future<bool> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      _clearError();
      
      final comment = PostComment(
        id: '',
        postId: postId,
        authorId: '', // จะถูกกำหนดใน service
        authorName: '', // จะถูกกำหนดใน service
        authorAvatar: null, // จะถูกกำหนดใน service
        content: content,
        likedBy: [],
        likeCount: 0,
        createdAt: DateTime.now(), // จะถูก override ใน service
        updatedAt: DateTime.now(), // จะถูก override ใน service
        parentCommentId: parentCommentId,
      );

      final commentId = await _communityService.addComment(comment);
      
      if (commentId != null) {
        _clearError();
        // Stream จะอัพเดทอัตโนมัติ
        return true;
      }
      
      _setError('ไม่สามารถเพิ่มคอมเมนต์ได้');
      return false;
    } catch (e) {
      _setError('ไม่สามารถเพิ่มคอมเมนต์ได้: $e');
      return false;
    }
  }

  // ลบคอมเมนต์
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      _clearError();
      final success = await _communityService.deleteComment(commentId, postId);
      
      if (!success) {
        _setError('ไม่สามารถลบคอมเมนต์ได้');
      }
      
      // Stream จะอัพเดทอัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถลบคอมเมนต์ได้: $e');
      return false;
    }
  }

  // กดไลค์คอมเมนต์ - แก้ไขเพื่อ Real-time
  Future<bool> toggleCommentLike(String commentId) async {
    try {
      _clearError();
      final success = await _communityService.toggleCommentLike(commentId);
      
      if (!success) {
        _setError('ไม่สามารถกดไลค์คอมเมนต์ได้');
      }
      
      // Stream จะอัพเดท like count อัตโนมัติ
      return success;
    } catch (e) {
      _setError('ไม่สามารถกดไลค์คอมเมนต์ได้: $e');
      return false;
    }
  }

  // ==================== UTILITY METHODS ====================

  // ล้างข้อผิดพลาด
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // ล้างโพสต์ปัจจุบัน
  void clearCurrentPosts() {
    _postsSubscription?.cancel();
    _currentGroupPosts = [];
    notifyListeners();
  }

  // ล้างคอมเมนต์ปัจจุบัน
  void clearCurrentComments() {
    _commentsSubscription?.cancel();
    _currentPostComments = [];
    notifyListeners();
  }

  // ตั้งค่าสถานะโหลด
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // ตั้งค่าสถานะโหลดโพสต์
  void _setLoadingPosts(bool loading) {
    _isLoadingPosts = loading;
    notifyListeners();
  }

  // ตั้งค่าสถานะโหลดคอมเมนต์
  void _setLoadingComments(bool loading) {
    _isLoadingComments = loading;
    notifyListeners();
  }

  // ตั้งค่าข้อผิดพลาด
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // รีเซ็ตทุกอย่าง
  void resetAll() {
    _allGroupsSubscription?.cancel();
    _userGroupsSubscription?.cancel();
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
    
    _allGroups = [];
    _userGroups = [];
    _currentGroupPosts = [];
    _currentPostComments = [];
    _isLoading = false;
    _isLoadingPosts = false;
    _isLoadingComments = false;
    _error = null;
    
    notifyListeners();
  }

  // รีเฟรชข้อมูลทั้งหมด
  void refreshAll() {
    loadAllGroups();
    loadUserGroups();
  }

  // รีเฟรชโพสต์ในกลุ่มปัจจุบัน
  void refreshCurrentGroupPosts(String groupId) {
    loadGroupPosts(groupId);
  }

  // รีเฟรชคอมเมนต์ในโพสต์ปัจจุบัน
  void refreshCurrentPostComments(String postId) {
    loadPostComments(postId);
  }

  // ==================== ADVANCED FEATURES ====================

  // หากลุ่มตาม ID
  CommunityGroup? findGroupById(String groupId) {
    try {
      return _allGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      return _userGroups.firstWhere((group) => group.id == groupId);
    }
  }

  // หาโพสต์ตาม ID
  CommunityPost? findPostById(String postId) {
    try {
      return _currentGroupPosts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  // ตรวจสอบว่าเป็นสมาชิกของกลุ่มหรือไม่
  bool isGroupMember(String groupId) {
    return _userGroups.any((group) => group.id == groupId);
  }

  // ตรวจสอบว่าได้ไลค์โพสต์แล้วหรือไม่
  bool isPostLiked(String postId) {
    final post = findPostById(postId);
    if (post == null) return false;
    return post.likedBy.contains(_communityService.currentUserId);
  }

  // ตรวจสอบว่าได้ไลค์คอมเมนต์แล้วหรือไม่
  bool isCommentLiked(String commentId) {
    try {
      final comment = _currentPostComments.firstWhere((c) => c.id == commentId);
      return comment.likedBy.contains(_communityService.currentUserId);
    } catch (e) {
      return false;
    }
  }

  // นับจำนวนกลุ่มทั้งหมด
  int get totalGroupsCount => _allGroups.length;

  // นับจำนวนกลุ่มที่เข้าร่วม
  int get joinedGroupsCount => _userGroups.length;

  // นับจำนวนโพสต์ในกลุ่มปัจจุบัน
  int get currentGroupPostsCount => _currentGroupPosts.length;

  // นับจำนวนคอมเมนต์ในโพสต์ปัจจุบัน
  int get currentPostCommentsCount => _currentPostComments.length;

  // ==================== SEARCH AND FILTER ====================

  // กรองกลุ่มตามแท็ก
  List<CommunityGroup> filterGroupsByTag(String tag) {
    return _allGroups.where((group) => 
      group.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
    ).toList();
  }

  // กรองกลุ่มตามชื่อ
  List<CommunityGroup> filterGroupsByName(String name) {
    return _allGroups.where((group) => 
      group.name.toLowerCase().contains(name.toLowerCase())
    ).toList();
  }

  // เรียงลำดับกลุ่มตามสมาชิก
  List<CommunityGroup> get groupsSortedByMembers {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return groups;
  }

  // เรียงลำดับกลุ่มตามโพสต์
  List<CommunityGroup> get groupsSortedByPosts {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.postCount.compareTo(a.postCount));
    return groups;
  }

  // เรียงลำดับโพสต์ตามไลค์
  List<CommunityPost> get postsSortedByLikes {
    final posts = List<CommunityPost>.from(_currentGroupPosts);
    posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return posts;
  }

  // โพสต์ที่ได้ไลค์มากที่สุด
  CommunityPost? get mostLikedPost {
    if (_currentGroupPosts.isEmpty) return null;
    return _currentGroupPosts.reduce((a, b) => 
      a.likeCount > b.likeCount ? a : b
    );
  }

  // โพสต์ล่าสุด
  CommunityPost? get latestPost {
    if (_currentGroupPosts.isEmpty) return null;
    return _currentGroupPosts.first; // เพราะเรียงตาม createdAt desc
  }

  // ==================== STATISTICS ====================

  // สถิติการโพสต์ของผู้ใช้
  int getUserPostCount(String userId) {
    return _currentGroupPosts.where((post) => post.authorId == userId).length;
  }

  // สถิติการไลค์ของผู้ใช้
  int getUserLikeCount(String userId) {
    return _currentGroupPosts
        .where((post) => post.authorId == userId)
        .fold(0, (sum, post) => sum + post.likeCount);
  }

  // สถิติการคอมเมนต์ของผู้ใช้
  int getUserCommentCount(String userId) {
    return _currentPostComments.where((comment) => comment.authorId == userId).length;
  }
}