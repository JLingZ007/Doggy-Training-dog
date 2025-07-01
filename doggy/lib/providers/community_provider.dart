// providers/community_provider.dart - เต็มรูปแบบรองรับ Base64
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/community_models.dart';
import '../services/community_service.dart';

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

  // Track initialization
  bool _isInitialized = false;

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
  bool get isInitialized => _isInitialized;

  @override
  void dispose() {
    print('CommunityProvider disposing...');
    _allGroupsSubscription?.cancel();
    _userGroupsSubscription?.cancel();
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
    super.dispose();
  }

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) {
      print('CommunityProvider already initialized');
      return;
    }

    print('Initializing CommunityProvider...');
    
    try {
      await _communityService.debugFirestoreConnection();
      
      loadAllGroups();
      loadUserGroups();
      
      _isInitialized = true;
      _clearError();
      print('CommunityProvider initialized successfully');
    } catch (e) {
      _setError('ไม่สามารถเริ่มต้นระบบได้: $e');
      print('Error initializing CommunityProvider: $e');
    }
  }

  // ==================== GROUP METHODS ====================

  void loadAllGroups() {
    print('Loading all groups...');
    _allGroupsSubscription?.cancel();
    
    if (_allGroups.isEmpty) {
      _setLoading(true);
    }
    
    _allGroupsSubscription = _communityService.getAllGroups().listen(
      (groups) {
        print('Received ${groups.length} groups from service');
        _allGroups = groups;
        _setLoading(false);
        _clearError();
        
        for (var group in groups) {
          print('Group: ${group.name} (ID: ${group.id}, Members: ${group.memberCount})');
        }
      },
      onError: (error) {
        print('Error in loadAllGroups: $error');
        _setError('ไม่สามารถโหลดกลุ่มได้: $error');
        _setLoading(false);
      },
    );
  }

  void loadUserGroups() {
    print('Loading user groups...');
    _userGroupsSubscription?.cancel();
    
    if (_userGroups.isEmpty) {
      _setLoading(true);
    }
    
    _userGroupsSubscription = _communityService.getUserGroups().listen(
      (groups) {
        print('Received ${groups.length} user groups from service');
        _userGroups = groups;
        _setLoading(false);
        _clearError();
        
        for (var group in groups) {
          print('User Group: ${group.name} (ID: ${group.id})');
        }
      },
      onError: (error) {
        print('Error in loadUserGroups: $error');
        _setError('ไม่สามารถโหลดกลุ่มของคุณได้: $error');
        _setLoading(false);
      },
    );
  }

  Future<bool> createGroup(CommunityGroup group) async {
    print('Creating group: ${group.name}');
    _setLoading(true);
    try {
      final groupId = await _communityService.createGroup(group);
      _setLoading(false);
      
      if (groupId != null) {
        print('Group created successfully with ID: $groupId');
        _clearError();
        return true;
      }
      
      _setError('ไม่สามารถสร้างกลุ่มได้');
      return false;
    } catch (e) {
      print('Error creating group: $e');
      _setLoading(false);
      _setError('ไม่สามารถสร้างกลุ่มได้: $e');
      return false;
    }
  }

  Future<List<CommunityGroup>> searchGroups(String query) async {
    try {
      print('Searching groups with query: $query');
      _clearError();
      final results = await _communityService.searchGroups(query);
      print('Search returned ${results.length} results');
      return results;
    } catch (e) {
      print('Error searching groups: $e');
      _setError('ไม่สามารถค้นหากลุ่มได้: $e');
      return [];
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      print('Joining group: $groupId');
      _clearError();
      final success = await _communityService.joinGroup(groupId);
      
      if (success) {
        print('Successfully joined group: $groupId');
      } else {
        print('Failed to join group: $groupId');
        _setError('ไม่สามารถเข้าร่วมกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error joining group: $e');
      _setError('ไม่สามารถเข้าร่วมกลุ่มได้: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      print('Leaving group: $groupId');
      _clearError();
      final success = await _communityService.leaveGroup(groupId);
      
      if (success) {
        print('Successfully left group: $groupId');
      } else {
        print('Failed to leave group: $groupId');
        _setError('ไม่สามารถออกจากกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error leaving group: $e');
      _setError('ไม่สามารถออกจากกลุ่มได้: $e');
      return false;
    }
  }

  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    print('Getting members for group: $groupId');
    return _communityService.getGroupMembers(groupId);
  }

  // ==================== POST METHODS (อัพเดทสำหรับ Base64) ====================

  void loadGroupPosts(String groupId) {
    print('Loading posts for group: $groupId');
    _postsSubscription?.cancel();
    _setLoadingPosts(true);
    
    _postsSubscription = _communityService.getGroupPosts(groupId).listen(
      (posts) {
        print('Received ${posts.length} posts for group $groupId');
        _currentGroupPosts = posts;
        _setLoadingPosts(false);
        _clearError();
        
        for (var post in posts.take(3)) {
          print('Post: ${post.content.substring(0, post.content.length > 30 ? 30 : post.content.length)}... (Likes: ${post.likeCount})');
        }
      },
      onError: (error) {
        print('Error in loadGroupPosts: $error');
        _setError('ไม่สามารถโหลดโพสต์ได้: $error');
        _setLoadingPosts(false);
      },
    );
  }

  /// สร้างโพสต์ใหม่พร้อมรองรับ Base64 Images
  Future<bool> createPost({
    required String groupId,
    required String content,
    List<File>? imageFiles,
    File? videoFile,
    bool useBase64 = true, // ใช้ Base64 เป็นค่าเริ่มต้น
  }) async {
    print('Creating post in group: $groupId (useBase64: $useBase64)');
    _setLoading(true);
    
    try {
      List<String> imageUrls = [];
      List<String> imageBase64s = [];
      String? videoUrl;
      String? videoBase64;

      // จัดการรูปภาพ
      if (imageFiles != null && imageFiles.isNotEmpty) {
        print('Processing ${imageFiles.length} images...');
        
        if (useBase64) {
          // แปลงเป็น Base64
          for (File imageFile in imageFiles) {
            final base64String = await _communityService.convertImageToBase64(imageFile);
            if (base64String != null) {
              imageBase64s.add(base64String);
              print('Image converted to Base64 (${base64String.length} chars)');
            }
          }
        } else {
          // อัพโหลดไป Firebase Storage
          for (File imageFile in imageFiles) {
            final url = await _communityService.uploadImage(imageFile, 'community_posts');
            if (url != null) {
              imageUrls.add(url);
              print('Image uploaded: $url');
            }
          }
        }
      }

      // จัดการวิดีโอ
      if (videoFile != null) {
        print('Processing video...');
        
        if (useBase64) {
          // แปลงเป็น Base64 (เฉพาะไฟล์เล็ก)
          videoBase64 = await _communityService.convertVideoToBase64(videoFile);
          if (videoBase64 != null) {
            print('Video converted to Base64 (${videoBase64.length} chars)');
          } else {
            print('Video too large for Base64, uploading to Storage...');
            videoUrl = await _communityService.uploadVideo(videoFile, 'community_posts');
          }
        } else {
          // อัพโหลดไป Firebase Storage
          videoUrl = await _communityService.uploadVideo(videoFile, 'community_posts');
          if (videoUrl != null) {
            print('Video uploaded: $videoUrl');
          }
        }
      }

      // กำหนดประเภทโพสต์
      PostType postType = PostType.text;
      bool hasImages = imageUrls.isNotEmpty || imageBase64s.isNotEmpty;
      bool hasVideo = videoUrl != null || videoBase64 != null;
      
      if (hasImages && hasVideo) {
        postType = PostType.mixed;
      } else if (hasImages) {
        postType = PostType.image;
      } else if (hasVideo) {
        postType = PostType.video;
      }

      // สร้างโพสต์
      final post = CommunityPost(
        id: '',
        groupId: groupId,
        authorId: '',
        authorName: '',
        content: content,
        imageUrls: imageUrls,
        imageBase64s: imageBase64s,
        videoUrl: videoUrl,
        videoBase64: videoBase64,
        type: postType,
        likedBy: [],
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final postId = await _communityService.createPost(post);
      _setLoading(false);
      
      if (postId != null) {
        print('Post created successfully with ID: $postId');
        _clearError();
        return true;
      }
      
      _setError('ไม่สามารถสร้างโพสต์ได้');
      return false;
    } catch (e) {
      print('Error creating post: $e');
      _setLoading(false);
      _setError('ไม่สามารถสร้างโพสต์ได้: $e');
      return false;
    }
  }

  Future<bool> deletePost(String postId, String groupId) async {
    try {
      print('Deleting post: $postId');
      _clearError();
      final success = await _communityService.deletePost(postId, groupId);
      
      if (success) {
        print('Post deleted successfully: $postId');
      } else {
        print('Failed to delete post: $postId');
        _setError('ไม่สามารถลบโพสต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error deleting post: $e');
      _setError('ไม่สามารถลบโพสต์ได้: $e');
      return false;
    }
  }

  Future<bool> togglePostLike(String postId) async {
    try {
      print('Toggling like for post: $postId');
      _clearError();
      
      // Optimistic update
      final postIndex = _currentGroupPosts.indexWhere((post) => post.id == postId);
      if (postIndex != -1) {
        final post = _currentGroupPosts[postIndex];
        final currentUserId = _communityService.currentUserId;
        
        if (currentUserId != null) {
          final isCurrentlyLiked = post.likedBy.contains(currentUserId);
          final newLikedBy = List<String>.from(post.likedBy);
          
          if (isCurrentlyLiked) {
            newLikedBy.remove(currentUserId);
          } else {
            newLikedBy.add(currentUserId);
          }
          
          _currentGroupPosts[postIndex] = post.copyWith(
            likedBy: newLikedBy,
            likeCount: newLikedBy.length,
          );
          notifyListeners();
        }
      }
      
      final success = await _communityService.togglePostLike(postId);
      
      if (success) {
        print('Post like toggled successfully: $postId');
      } else {
        print('Failed to toggle post like: $postId');
        _setError('ไม่สามารถกดไลค์ได้');
        loadGroupPosts(_currentGroupPosts.isNotEmpty ? _currentGroupPosts.first.groupId : '');
      }
      
      return success;
    } catch (e) {
      print('Error toggling post like: $e');
      _setError('ไม่สามารถกดไลค์ได้: $e');
      if (_currentGroupPosts.isNotEmpty) {
        loadGroupPosts(_currentGroupPosts.first.groupId);
      }
      return false;
    }
  }

  // ==================== COMMENT METHODS ====================

  void loadPostComments(String postId) {
    print('Loading comments for post: $postId');
    _commentsSubscription?.cancel();
    _setLoadingComments(true);
    
    _commentsSubscription = _communityService.getPostComments(postId).listen(
      (comments) {
        print('Received ${comments.length} comments for post $postId');
        _currentPostComments = comments;
        _setLoadingComments(false);
        _clearError();
      },
      onError: (error) {
        print('Error in loadPostComments: $error');
        _setError('ไม่สามารถโหลดคอมเมนต์ได้: $error');
        _setLoadingComments(false);
      },
    );
  }

  Future<bool> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      print('Adding comment to post: $postId');
      _clearError();
      
      final comment = PostComment(
        id: '',
        postId: postId,
        authorId: '',
        authorName: '',
        content: content,
        likedBy: [],
        likeCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      final commentId = await _communityService.addComment(comment);
      
      if (commentId != null) {
        print('Comment added successfully with ID: $commentId');
        _clearError();
        return true;
      }
      
      _setError('ไม่สามารถเพิ่มคอมเมนต์ได้');
      return false;
    } catch (e) {
      print('Error adding comment: $e');
      _setError('ไม่สามารถเพิ่มคอมเมนต์ได้: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      print('Deleting comment: $commentId');
      _clearError();
      final success = await _communityService.deleteComment(commentId, postId);
      
      if (success) {
        print('Comment deleted successfully: $commentId');
      } else {
        print('Failed to delete comment: $commentId');
        _setError('ไม่สามารถลบคอมเมนต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error deleting comment: $e');
      _setError('ไม่สามารถลบคอมเมนต์ได้: $e');
      return false;
    }
  }

  Future<bool> toggleCommentLike(String commentId) async {
    try {
      print('Toggling like for comment: $commentId');
      _clearError();
      
      // Optimistic update
      final commentIndex = _currentPostComments.indexWhere((comment) => comment.id == commentId);
      if (commentIndex != -1) {
        final comment = _currentPostComments[commentIndex];
        final currentUserId = _communityService.currentUserId;
        
        if (currentUserId != null) {
          final isCurrentlyLiked = comment.likedBy.contains(currentUserId);
          final newLikedBy = List<String>.from(comment.likedBy);
          
          if (isCurrentlyLiked) {
            newLikedBy.remove(currentUserId);
          } else {
            newLikedBy.add(currentUserId);
          }
          
          _currentPostComments[commentIndex] = comment.copyWith(
            likedBy: newLikedBy,
            likeCount: newLikedBy.length,
          );
          notifyListeners();
        }
      }
      
      final success = await _communityService.toggleCommentLike(commentId);
      
      if (success) {
        print('Comment like toggled successfully: $commentId');
      } else {
        print('Failed to toggle comment like: $commentId');
        _setError('ไม่สามารถกดไลค์คอมเมนต์ได้');
        if (_currentPostComments.isNotEmpty) {
          loadPostComments(_currentPostComments.first.postId);
        }
      }
      
      return success;
    } catch (e) {
      print('Error toggling comment like: $e');
      _setError('ไม่สามารถกดไลค์คอมเมนต์ได้: $e');
      if (_currentPostComments.isNotEmpty) {
        loadPostComments(_currentPostComments.first.postId);
      }
      return false;
    }
  }

  // ==================== UTILITY METHODS ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearCurrentPosts() {
    print('Clearing current posts');
    _postsSubscription?.cancel();
    _currentGroupPosts = [];
    notifyListeners();
  }

  void clearCurrentComments() {
    print('Clearing current comments');
    _commentsSubscription?.cancel();
    _currentPostComments = [];
    notifyListeners();
  }

  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setLoadingPosts(bool loading) {
    if (_isLoadingPosts != loading) {
      _isLoadingPosts = loading;
      notifyListeners();
    }
  }

  void _setLoadingComments(bool loading) {
    if (_isLoadingComments != loading) {
      _isLoadingComments = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    print('Setting error: $error');
    _error = error;
    notifyListeners();
  }

  void resetAll() {
    print('Resetting all data');
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
    _isInitialized = false;
    
    notifyListeners();
  }

  void refreshAll() {
    print('Refreshing all data');
    loadAllGroups();
    loadUserGroups();
  }

  void refreshCurrentGroupPosts(String groupId) {
    print('Refreshing posts for group: $groupId');
    loadGroupPosts(groupId);
  }

  void refreshCurrentPostComments(String postId) {
    print('Refreshing comments for post: $postId');
    loadPostComments(postId);
  }

  // ==================== ADVANCED FEATURES ====================

  CommunityGroup? findGroupById(String groupId) {
    try {
      return _allGroups.firstWhere((group) => group.id == groupId);
    } catch (e) {
      try {
        return _userGroups.firstWhere((group) => group.id == groupId);
      } catch (e) {
        return null;
      }
    }
  }

  CommunityPost? findPostById(String postId) {
    try {
      return _currentGroupPosts.firstWhere((post) => post.id == postId);
    } catch (e) {
      return null;
    }
  }

  bool isGroupMember(String groupId) {
    final isMember = _userGroups.any((group) => group.id == groupId);
    print('User is member of group $groupId: $isMember');
    return isMember;
  }

  bool isPostLiked(String postId) {
    final post = findPostById(postId);
    if (post == null) return false;
    final currentUserId = _communityService.currentUserId;
    if (currentUserId == null) return false;
    return post.likedBy.contains(currentUserId);
  }

  bool isCommentLiked(String commentId) {
    try {
      final comment = _currentPostComments.firstWhere((c) => c.id == commentId);
      final currentUserId = _communityService.currentUserId;
      if (currentUserId == null) return false;
      return comment.likedBy.contains(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // Statistics
  int get totalGroupsCount => _allGroups.length;
  int get joinedGroupsCount => _userGroups.length;
  int get currentGroupPostsCount => _currentGroupPosts.length;
  int get currentPostCommentsCount => _currentPostComments.length;

  // Search and Filter
  List<CommunityGroup> filterGroupsByTag(String tag) {
    return _allGroups.where((group) => 
      group.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
    ).toList();
  }

  List<CommunityGroup> filterGroupsByName(String name) {
    return _allGroups.where((group) => 
      group.name.toLowerCase().contains(name.toLowerCase())
    ).toList();
  }

  List<CommunityGroup> get groupsSortedByMembers {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return groups;
  }

  List<CommunityGroup> get groupsSortedByPosts {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.postCount.compareTo(a.postCount));
    return groups;
  }

  List<CommunityPost> get postsSortedByLikes {
    final posts = List<CommunityPost>.from(_currentGroupPosts);
    posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return posts;
  }

  CommunityPost? get mostLikedPost {
    if (_currentGroupPosts.isEmpty) return null;
    return _currentGroupPosts.reduce((a, b) => 
      a.likeCount > b.likeCount ? a : b
    );
  }

  CommunityPost? get latestPost {
    if (_currentGroupPosts.isEmpty) return null;
    return _currentGroupPosts.first;
  }

  int getUserPostCount(String userId) {
    return _currentGroupPosts.where((post) => post.authorId == userId).length;
  }

  int getUserLikeCount(String userId) {
    return _currentGroupPosts
        .where((post) => post.authorId == userId)
        .fold(0, (sum, post) => sum + post.likeCount);
  }

  int getUserCommentCount(String userId) {
    return _currentPostComments.where((comment) => comment.authorId == userId).length;
  }

  // ==================== BASE64 IMAGE HELPERS ====================

  /// ตรวจสอบว่าสตริงเป็น Base64 หรือไม่
  bool isBase64String(String str) {
    return str.startsWith('data:') && str.contains('base64,');
  }

  /// แปลง Base64 กลับเป็น bytes (สำหรับแสดงผล)
  List<int>? decodeBase64(String base64String) {
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

  /// ดึง MIME type จาก Base64 string
  String? getMimeTypeFromBase64(String base64String) {
    try {
      if (base64String.startsWith('data:')) {
        final mimeType = base64String.split(';')[0].substring(5);
        return mimeType;
      }
      return null;
    } catch (e) {
      print('Error getting mime type: $e');
      return null;
    }
  }

  // ==================== IMAGE CONVERSION HELPERS ====================

  /// แปลงไฟล์รูปภาพเป็น Base64 ผ่าน Service
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      return await _communityService.convertImageToBase64(imageFile);
    } catch (e) {
      print('Error converting image to base64 in provider: $e');
      return null;
    }
  }

  /// แปลงไฟล์วิดีโอเป็น Base64 ผ่าน Service
  Future<String?> convertVideoToBase64(File videoFile) async {
    try {
      return await _communityService.convertVideoToBase64(videoFile);
    } catch (e) {
      print('Error converting video to base64 in provider: $e');
      return null;
    }
  }

  /// อัพโหลดรูปภาพไป Firebase Storage ผ่าน Service
  Future<String?> uploadImageToStorage(File imageFile, String folder) async {
    try {
      return await _communityService.uploadImage(imageFile, folder);
    } catch (e) {
      print('Error uploading image to storage in provider: $e');
      return null;
    }
  }

  /// อัพโหลดวิดีโอไป Firebase Storage ผ่าน Service
  Future<String?> uploadVideoToStorage(File videoFile, String folder) async {
    try {
      return await _communityService.uploadVideo(videoFile, folder);
    } catch (e) {
      print('Error uploading video to storage in provider: $e');
      return null;
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// สร้างโพสต์หลายๆ โพสต์พร้อมกัน
  Future<List<String?>> createMultiplePosts(List<CommunityPost> posts) async {
    final results = <String?>[];
    
    for (var post in posts) {
      try {
        final postId = await _communityService.createPost(post);
        results.add(postId);
      } catch (e) {
        print('Error creating post in batch: $e');
        results.add(null);
      }
    }
    
    return results;
  }

  /// ลบโพสต์หลายๆ โพสต์พร้อมกัน
  Future<List<bool>> deleteMultiplePosts(List<String> postIds, String groupId) async {
    final results = <bool>[];
    
    for (var postId in postIds) {
      try {
        final success = await _communityService.deletePost(postId, groupId);
        results.add(success);
      } catch (e) {
        print('Error deleting post in batch: $e');
        results.add(false);
      }
    }
    
    return results;
  }

  // ==================== MEDIA MANAGEMENT ====================

  /// ดึงขนาดไฟล์ในรูปแบบที่อ่านง่าย
  String getFileSizeString(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// ตรวจสอบขนาดไฟล์ว่าเหมาะสำหรับ Base64 หรือไม่
  Future<bool> isFileSuitableForBase64(File file, {int maxSizeMB = 5}) async {
    try {
      final fileSize = await file.length();
      final maxSizeBytes = maxSizeMB * 1024 * 1024;
      return fileSize <= maxSizeBytes;
    } catch (e) {
      print('Error checking file size: $e');
      return false;
    }
  }

  /// แนะนำวิธีการอัพโหลดที่เหมาะสม
  Future<String> getRecommendedUploadMethod(File file) async {
    try {
      final fileSize = await file.length();
      final fileSizeString = getFileSizeString(fileSize);
      
      if (fileSize <= 1024 * 1024) { // <= 1MB
        return 'Base64 (แนะนำ) - ขนาดไฟล์: $fileSizeString';
      } else if (fileSize <= 5 * 1024 * 1024) { // <= 5MB
        return 'Base64 หรือ Storage - ขนาดไฟล์: $fileSizeString';
      } else {
        return 'Firebase Storage (แนะนำ) - ขนาดไฟล์: $fileSizeString';
      }
    } catch (e) {
      return 'ไม่สามารถตรวจสอบขนาดไฟล์ได้';
    }
  }

  // ==================== VALIDATION HELPERS ====================

  /// ตรวจสอบว่าไฟล์เป็นรูปภาพหรือไม่
  bool isImageFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// ตรวจสอบว่าไฟล์เป็นวิดีโอหรือไม่
  bool isVideoFile(File file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(extension);
  }

  /// ตรวจสอบความถูกต้องของเนื้อหาโพสต์
  String? validatePostContent(String content, {int maxLength = 5000}) {
    if (content.trim().isEmpty) {
      return 'กรุณาใส่เนื้อหาโพสต์';
    }
    if (content.length > maxLength) {
      return 'เนื้อหาโพสต์ยาวเกินไป (สูงสุด $maxLength ตัวอักษร)';
    }
    return null; // ถูกต้อง
  }

  /// ตรวจสอบความถูกต้องของรูปภาพ
  Future<String?> validateImages(List<File> imageFiles, {int maxCount = 10}) async {
    if (imageFiles.length > maxCount) {
      return 'สามารถเลือกรูปภาพได้สูงสุด $maxCount รูป';
    }

    for (var file in imageFiles) {
      if (!isImageFile(file)) {
        return 'ไฟล์ ${file.path.split('/').last} ไม่ใช่รูปภาพ';
      }
      
      final fileSize = await file.length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB
        return 'รูปภาพ ${file.path.split('/').last} มีขนาดใหญ่เกินไป (สูงสุด 50MB)';
      }
    }
    
    return null; // ถูกต้อง
  }

  /// ตรวจสอบความถูกต้องของวิดีโอ
  Future<String?> validateVideo(File videoFile) async {
    if (!isVideoFile(videoFile)) {
      return 'ไฟล์ ${videoFile.path.split('/').last} ไม่ใช่วิดีโอ';
    }
    
    final fileSize = await videoFile.length();
    if (fileSize > 100 * 1024 * 1024) { // 100MB
      return 'วิดีโอมีขนาดใหญ่เกินไป (สูงสุด 100MB)';
    }
    
    return null; // ถูกต้อง
  }

  // ==================== CACHE MANAGEMENT ====================

  /// ล้างแคช Base64 ที่เก่า (สำหรับประหยัด memory)
  void clearBase64Cache() {
    // ในอนาคตอาจเพิ่มระบบแคช Base64 เพื่อประหยัด memory
    print('Base64 cache cleared (placeholder)');
  }

  /// ประมาณขนาด memory ที่ใช้สำหรับ Base64
  int estimateBase64MemoryUsage() {
    int totalSize = 0;
    
    for (var post in _currentGroupPosts) {
      for (var base64String in post.imageBase64s) {
        // Base64 ใช้ memory ประมาณ 1.33 เท่าของขนาดจริง
        totalSize += (base64String.length * 0.75).round();
      }
      if (post.videoBase64 != null) {
        totalSize += (post.videoBase64!.length * 0.75).round();
      }
    }
    
    return totalSize;
  }

  /// แสดงสถิติการใช้ memory
  String getMemoryUsageInfo() {
    final memoryUsage = estimateBase64MemoryUsage();
    return getFileSizeString(memoryUsage);
  }

  // ==================== DEBUG AND MONITORING ====================

  /// แสดงสถิติของ Provider
  void printProviderStats() {
    print('=== CommunityProvider Statistics ===');
    print('All Groups: ${_allGroups.length}');
    print('User Groups: ${_userGroups.length}');
    print('Current Posts: ${_currentGroupPosts.length}');
    print('Current Comments: ${_currentPostComments.length}');
    print('Memory Usage (Base64): ${getMemoryUsageInfo()}');
    print('Is Loading: $_isLoading');
    print('Is Loading Posts: $_isLoadingPosts');
    print('Is Loading Comments: $_isLoadingComments');
    print('Error: ${_error ?? 'None'}');
    print('Is Initialized: $_isInitialized');
    print('================================');
  }

  /// ส่งออกข้อมูลสำหรับ debug
  Map<String, dynamic> getDebugInfo() {
    return {
      'allGroupsCount': _allGroups.length,
      'userGroupsCount': _userGroups.length,
      'currentPostsCount': _currentGroupPosts.length,
      'currentCommentsCount': _currentPostComments.length,
      'memoryUsage': getMemoryUsageInfo(),
      'isLoading': _isLoading,
      'isLoadingPosts': _isLoadingPosts,
      'isLoadingComments': _isLoadingComments,
      'error': _error,
      'isInitialized': _isInitialized,
      'hasActiveSubscriptions': {
        'allGroups': _allGroupsSubscription != null,
        'userGroups': _userGroupsSubscription != null,
        'posts': _postsSubscription != null,
        'comments': _commentsSubscription != null,
      },
    };
  }

  // ==================== EXPORT/IMPORT FUNCTIONALITY ====================

  /// ส่งออกข้อมูลโพสต์เป็น JSON (สำหรับ backup)
  Map<String, dynamic> exportPostsToJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'posts': _currentGroupPosts.map((post) => post.toFirestore()).toList(),
    };
  }

  /// ส่งออกข้อมูลกลุ่มเป็น JSON (สำหรับ backup)
  Map<String, dynamic> exportGroupsToJson() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'allGroups': _allGroups.map((group) => group.toFirestore()).toList(),
      'userGroups': _userGroups.map((group) => group.toFirestore()).toList(),
    };
  }

  // ==================== PERFORMANCE OPTIMIZATION ====================

  /// จำกัดจำนวนโพสต์ในหน่วยความจำ
  void limitPostsInMemory({int maxPosts = 100}) {
    if (_currentGroupPosts.length > maxPosts) {
      _currentGroupPosts = _currentGroupPosts.take(maxPosts).toList();
      print('Limited posts in memory to $maxPosts items');
      notifyListeners();
    }
  }

  /// จำกัดจำนวนคอมเมนต์ในหน่วยความจำ
  void limitCommentsInMemory({int maxComments = 200}) {
    if (_currentPostComments.length > maxComments) {
      _currentPostComments = _currentPostComments.take(maxComments).toList();
      print('Limited comments in memory to $maxComments items');
      notifyListeners();
    }
  }

  /// ทำความสะอาดข้อมูลเก่าออกจากหน่วยความจำ
  void cleanupOldData() {
    limitPostsInMemory();
    limitCommentsInMemory();
    clearBase64Cache();
    print('Cleanup completed');
  }
}