// providers/community_provider.dart - Complete Cloudinary Integration
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';
import '../models/community_models.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();
  
  // ==================== STATE VARIABLES ====================
  
  // Groups
  List<CommunityGroup> _allGroups = [];
  List<CommunityGroup> _userGroups = [];
  
  // Posts
  List<CommunityPost> _currentGroupPosts = [];
  CommunityGroup? _selectedGroup;
  
  // Comments
  List<PostComment> _currentPostComments = [];
  CommunityPost? _selectedPost;
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingPosts = false;
  bool _isLoadingComments = false;
  bool _isUploading = false;
  
  // Error handling
  String? _error;

  // Real-time subscriptions
  StreamSubscription? _allGroupsSubscription;
  StreamSubscription? _userGroupsSubscription;
  StreamSubscription? _postsSubscription;
  StreamSubscription? _commentsSubscription;

  // Initialization tracking
  bool _isInitialized = false;

  // Upload progress tracking
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // ==================== GETTERS ====================
  
  List<CommunityGroup> get allGroups => _allGroups;
  List<CommunityGroup> get userGroups => _userGroups;
  List<CommunityPost> get currentGroupPosts => _currentGroupPosts;
  List<PostComment> get currentPostComments => _currentPostComments;
  
  CommunityGroup? get selectedGroup => _selectedGroup;
  CommunityPost? get selectedPost => _selectedPost;
  
  bool get isLoading => _isLoading;
  bool get isLoadingPosts => _isLoadingPosts;
  bool get isLoadingComments => _isLoadingComments;
  bool get isUploading => _isUploading;
  
  double get uploadProgress => _uploadProgress;
  String get uploadStatus => _uploadStatus;
  
  String? get error => _error;
  CommunityService get communityService => _communityService;
  bool get isInitialized => _isInitialized;

  // ==================== LIFECYCLE ====================

  @override
  void dispose() {
    print('CommunityProvider disposing...');
    _cancelAllSubscriptions();
    super.dispose();
  }

  void _cancelAllSubscriptions() {
    _allGroupsSubscription?.cancel();
    _userGroupsSubscription?.cancel();
    _postsSubscription?.cancel();
    _commentsSubscription?.cancel();
  }

  // ==================== INITIALIZATION ====================

  Future<void> initialize() async {
    if (_isInitialized) {
      print('CommunityProvider already initialized');
      return;
    }

    print('Initializing CommunityProvider...');
    _setLoading(true);
    
    try {
      // Debug connection
      await _communityService.debugFirestoreConnection();
      
      // Start real-time listeners
      _startGroupListeners();
      
      _isInitialized = true;
      _clearError();
      print('CommunityProvider initialized successfully');
    } catch (e) {
      _setError('ไม่สามารถเริ่มต้นระบบได้: $e');
      print('Error initializing CommunityProvider: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _startGroupListeners() {
    loadAllGroups();
    loadUserGroups();
  }

  // ==================== STATE MANAGEMENT ====================

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

  void _setUploading(bool uploading) {
    if (_isUploading != uploading) {
      _isUploading = uploading;
      if (!uploading) {
        _uploadProgress = 0.0;
        _uploadStatus = '';
      }
      notifyListeners();
    }
  }

  void _setUploadProgress(double progress, String status) {
    _uploadProgress = progress;
    _uploadStatus = status;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // ==================== GROUP METHODS ====================

  void loadAllGroups() {
    print('Loading all groups...');
    _allGroupsSubscription?.cancel();
    
    _allGroupsSubscription = _communityService.getAllGroups().listen(
      (groups) {
        print('Received ${groups.length} groups from service');
        _allGroups = groups;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('Error in loadAllGroups: $error');
        _setError('ไม่สามารถโหลดกลุ่มได้: $error');
      },
    );
  }

  void loadUserGroups() {
    print('Loading user groups...');
    _userGroupsSubscription?.cancel();
    
    _userGroupsSubscription = _communityService.getUserGroups().listen(
      (groups) {
        print('Received ${groups.length} user groups from service');
        _userGroups = groups;
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('Error in loadUserGroups: $error');
        _setError('ไม่สามารถโหลดกลุ่มของคุณได้: $error');
      },
    );
  }

  Future<bool> createGroup(CreateGroupDto groupDto) async {
    print('Creating group: ${groupDto.name}');
    _setLoading(true);
    _setUploadProgress(0.0, 'เริ่มสร้างกลุ่ม...');
    
    try {
      _clearError();
      
      if (groupDto.coverImageFile != null) {
        _setUploadProgress(0.3, 'กำลังอัปโหลดรูปปก...');
      }
      
      _setUploadProgress(0.5, 'กำลังสร้างกลุ่ม...');
      
      // สร้าง CommunityGroup object
      final group = CommunityGroup(
        id: '', // จะถูกสร้างใน service
        name: groupDto.name,
        description: groupDto.description,
        tags: groupDto.tags,
        memberIds: [],
        memberCount: 0,
        postCount: 0,
        isPublic: groupDto.isPublic,
        createdBy: _communityService.currentUserId ?? '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        coverImageFile: groupDto.coverImageFile,
      );

      final groupId = await _communityService.createGroup(group);
      
      _setUploadProgress(1.0, 'สร้างกลุ่มเรียบร้อย');
      
      if (groupId != null) {
        print('Group created successfully with ID: $groupId');
        return true;
      } else {
        _setError('ไม่สามารถสร้างกลุ่มได้');
        return false;
      }
    } catch (e) {
      print('Error creating group: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setLoading(false);
      _setUploading(false);
    }
  }

  Future<List<CommunityGroup>> searchGroups(String query) async {
    try {
      print('Searching groups with query: $query');
      _clearError();
      return await _communityService.searchGroups(query);
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
      
      if (!success) {
        _setError('ไม่สามารถเข้าร่วมกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error joining group: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      print('Leaving group: $groupId');
      _clearError();
      final success = await _communityService.leaveGroup(groupId);
      
      if (!success) {
        _setError('ไม่สามารถออกจากกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error leaving group: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? description,
    List<String>? tags,
    XFile? newCoverImage,
    bool removeCoverImage = false,
  }) async {
    try {
      print('Updating group: $groupId');
      _setLoading(true);
      _clearError();

      final success = await _communityService.updateGroup(
        groupId: groupId,
        name: name,
        description: description,
        tags: tags,
        newCoverImage: newCoverImage,
        removeCoverImage: removeCoverImage,
      );
      
      if (!success) {
        _setError('ไม่สามารถแก้ไขกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error updating group: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      print('Deleting group: $groupId');
      _setLoading(true);
      _clearError();

      final success = await _communityService.deleteGroup(groupId);
      
      if (!success) {
        _setError('ไม่สามารถลบกลุ่มได้');
      }
      
      return success;
    } catch (e) {
      print('Error deleting group: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void selectGroup(CommunityGroup group) {
    print('Selecting group: ${group.name}');
    _selectedGroup = group;
    loadGroupPosts(group.id);
    notifyListeners();
  }

  void clearSelectedGroup() {
    print('Clearing selected group');
    _selectedGroup = null;
    clearCurrentPosts();
    notifyListeners();
  }

  // ==================== POST METHODS ====================

  void loadGroupPosts(String groupId) {
    print('Loading posts for group: $groupId');
    _postsSubscription?.cancel();
    _setLoadingPosts(true);
    
    _postsSubscription = _communityService.getGroupPosts(groupId: groupId).listen(
      (posts) {
        print('Received ${posts.length} posts for group $groupId');
        _currentGroupPosts = posts;
        _setLoadingPosts(false);
        _clearError();
        notifyListeners();
      },
      onError: (error) {
        print('Error in loadGroupPosts: $error');
        _setError('ไม่สามารถโหลดโพสต์ได้: $error');
        _setLoadingPosts(false);
      },
    );
  }

  Future<bool> createPost({
    required String groupId,
    required String content,
    List<XFile>? imageFiles,
    XFile? videoFile,
    PostType type = PostType.text,
  }) async {
    print('Creating post in group: $groupId');
    _setUploading(true);
    _setUploadProgress(0.0, 'เริ่มสร้างโพสต์...');
    
    try {
      _clearError();
      
      if (imageFiles != null && imageFiles.isNotEmpty) {
        _setUploadProgress(0.2, 'กำลังอัปโหลดรูปภาพ...');
      }
      
      if (videoFile != null) {
        _setUploadProgress(0.3, 'กำลังอัปโหลดวิดีโอ...');
      }
      
      _setUploadProgress(0.7, 'กำลังบันทึกโพสต์...');

      final postId = await _communityService.createPost(
        groupId: groupId,
        content: content,
        imageFiles: imageFiles,
        videoFile: videoFile,
        type: type,
      );
      
      _setUploadProgress(1.0, 'สร้างโพสต์เรียบร้อย');
      
      if (postId != null) {
        print('Post created successfully with ID: $postId');
        return true;
      } else {
        _setError('ไม่สามารถสร้างโพสต์ได้');
        return false;
      }
    } catch (e) {
      print('Error creating post: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setUploading(false);
    }
  }

  Future<bool> updatePost({
    required String postId,
    String? newContent,
    List<XFile>? newImageFiles,
    List<String>? imagesToDelete,
    XFile? newVideoFile,
    bool removeVideo = false,
  }) async {
    try {
      print('Updating post: $postId');
      _setUploading(true);
      _clearError();

      final success = await _communityService.updatePost(
        postId: postId,
        newContent: newContent,
        newImageFiles: newImageFiles,
        imagesToDelete: imagesToDelete,
        newVideoFile: newVideoFile,
        removeVideo: removeVideo,
      );
      
      if (!success) {
        _setError('ไม่สามารถแก้ไขโพสต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error updating post: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setUploading(false);
    }
  }

  Future<bool> deletePost(String postId, String groupId) async {
    try {
      print('Deleting post: $postId');
      _setLoading(true);
      _clearError();

      final success = await _communityService.deletePost(postId, groupId);
      
      if (!success) {
        _setError('ไม่สามารถลบโพสต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error deleting post: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> togglePostLike(String postId) async {
    try {
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
          );
          notifyListeners();
        }
      }
      
      final success = await _communityService.togglePostLike(postId);
      
      if (!success) {
        // Revert optimistic update
        if (postIndex != -1 && _selectedGroup != null) {
          loadGroupPosts(_selectedGroup!.id);
        }
        _setError('ไม่สามารถกดไลค์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error toggling post like: $e');
      // Revert optimistic update
      if (_selectedGroup != null) {
        loadGroupPosts(_selectedGroup!.id);
      }
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  void selectPost(CommunityPost post) {
    print('Selecting post: ${post.id}');
    _selectedPost = post;
    loadPostComments(post.id);
    notifyListeners();
  }

  void clearSelectedPost() {
    print('Clearing selected post');
    _selectedPost = null;
    clearCurrentComments();
    notifyListeners();
  }

  void clearCurrentPosts() {
    print('Clearing current posts');
    _postsSubscription?.cancel();
    _currentGroupPosts = [];
    notifyListeners();
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
        notifyListeners();
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

      final commentId = await _communityService.addComment(
        postId: postId,
        content: content,
        parentCommentId: parentCommentId,
      );
      
      if (commentId != null) {
        print('Comment added successfully with ID: $commentId');
        return true;
      } else {
        _setError('ไม่สามารถเพิ่มคอมเมนต์ได้');
        return false;
      }
    } catch (e) {
      print('Error adding comment: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      print('Deleting comment: $commentId');
      _clearError();

      final success = await _communityService.deleteComment(commentId, postId);
      
      if (!success) {
        _setError('ไม่สามารถลบคอมเมนต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error deleting comment: $e');
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  Future<bool> toggleCommentLike(String commentId) async {
    try {
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
          );
          notifyListeners();
        }
      }
      
      final success = await _communityService.toggleCommentLike(commentId);
      
      if (!success) {
        // Revert optimistic update
        if (commentIndex != -1 && _selectedPost != null) {
          loadPostComments(_selectedPost!.id);
        }
        _setError('ไม่สามารถกดไลค์คอมเมนต์ได้');
      }
      
      return success;
    } catch (e) {
      print('Error toggling comment like: $e');
      // Revert optimistic update
      if (_selectedPost != null) {
        loadPostComments(_selectedPost!.id);
      }
      _setError('เกิดข้อผิดพลาด: $e');
      return false;
    }
  }

  void clearCurrentComments() {
    print('Clearing current comments');
    _commentsSubscription?.cancel();
    _currentPostComments = [];
    notifyListeners();
  }

  // ==================== UTILITY METHODS ====================

  void refreshAll() {
    print('Refreshing all data');
    loadAllGroups();
    loadUserGroups();
    
    if (_selectedGroup != null) {
      loadGroupPosts(_selectedGroup!.id);
    }
    
    if (_selectedPost != null) {
      loadPostComments(_selectedPost!.id);
    }
  }

  void resetAll() {
    print('Resetting all data');
    _cancelAllSubscriptions();
    
    _allGroups = [];
    _userGroups = [];
    _currentGroupPosts = [];
    _currentPostComments = [];
    _selectedGroup = null;
    _selectedPost = null;
    
    _isLoading = false;
    _isLoadingPosts = false;
    _isLoadingComments = false;
    _isUploading = false;
    _uploadProgress = 0.0;
    _uploadStatus = '';
    
    _error = null;
    _isInitialized = false;
    
    notifyListeners();
  }

  // ==================== GROUP MEMBER METHODS ====================

  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    print('Getting members for group: $groupId');
    return _communityService.getGroupMembers(groupId);
  }

  // ==================== HELPER METHODS ====================

  bool isUserMemberOfGroup(String groupId) {
    final userId = _communityService.currentUserId;
    if (userId == null) return false;
    
    return _userGroups.any((group) => group.id == groupId);
  }

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

  bool isPostLiked(String postId) {
    final post = findPostById(postId);
    if (post == null) return false;
    final currentUserId = _communityService.currentUserId;
    if (currentUserId == null) return false;
    return post.isLikedBy(currentUserId);
  }

  bool isCommentLiked(String commentId) {
    try {
      final comment = _currentPostComments.firstWhere((c) => c.id == commentId);
      final currentUserId = _communityService.currentUserId;
      if (currentUserId == null) return false;
      return comment.isLikedBy(currentUserId);
    } catch (e) {
      return false;
    }
  }

  // ==================== STATISTICS ====================

  Map<String, dynamic> getGroupStatistics(String groupId) {
    final group = findGroupById(groupId);
    if (group == null) return {};

    final posts = _selectedGroup?.id == groupId ? _currentGroupPosts : <CommunityPost>[];
    final totalLikes = posts.fold<int>(0, (sum, post) => sum + post.likeCount);
    final totalComments = posts.fold<int>(0, (sum, post) => sum + post.commentCount);
    
    final postTypes = <PostType, int>{};
    for (final post in posts) {
      postTypes[post.type] = (postTypes[post.type] ?? 0) + 1;
    }

    return {
      'memberCount': group.memberCount,
      'postCount': group.postCount,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'postTypes': postTypes,
      'averageLikesPerPost': posts.isNotEmpty ? (totalLikes / posts.length).round() : 0,
      'averageCommentsPerPost': posts.isNotEmpty ? (totalComments / posts.length).round() : 0,
    };
  }

  Map<String, dynamic> getUserStatistics() {
    final userId = _communityService.currentUserId;
    if (userId == null) return {};

    final userPosts = _currentGroupPosts.where((post) => post.authorId == userId).toList();
    final userLikedPosts = _currentGroupPosts.where((post) => post.isLikedBy(userId)).toList();

    final totalLikesReceived = userPosts.fold<int>(0, (sum, post) => sum + post.likeCount);
    final totalCommentsReceived = userPosts.fold<int>(0, (sum, post) => sum + post.commentCount);

    return {
      'totalGroups': _userGroups.length,
      'totalPosts': userPosts.length,
      'totalLikesReceived': totalLikesReceived,
      'totalCommentsReceived': totalCommentsReceived,
      'totalLikesGiven': userLikedPosts.length,
      'averageLikesPerPost': userPosts.isNotEmpty ? (totalLikesReceived / userPosts.length).round() : 0,
    };
  }

  // ==================== SEARCH & FILTER ====================

  List<CommunityGroup> filterGroupsByTag(String tag) {
    return _allGroups.where((group) => 
      group.tags.any((t) => t.toLowerCase().contains(tag.toLowerCase()))
    ).toList();
  }

  List<CommunityGroup> filterGroupsByName(String name) {
    return _allGroups.where((group) => 
      group.name.toLowerCase().contains(name.toLowerCase()) ||
      group.description.toLowerCase().contains(name.toLowerCase())
    ).toList();
  }

  List<CommunityPost> searchPostsInCurrentGroup(String query) {
    if (query.isEmpty) return _currentGroupPosts;
    
    return _currentGroupPosts.where((post) {
      return post.content.toLowerCase().contains(query.toLowerCase()) ||
             post.authorName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<CommunityPost> filterPostsByType(PostType? type) {
    if (type == null) return _currentGroupPosts;
    
    return _currentGroupPosts.where((post) => post.type == type).toList();
  }

  // ==================== SORTING ====================

  List<CommunityGroup> get groupsSortedByMembers {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.memberCount.compareTo(a.memberCount));
    return groups;
  }

  List<CommunityGroup> get groupsSortedByActivity {
    final groups = List<CommunityGroup>.from(_allGroups);
    groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return groups;
  }

  List<CommunityPost> get postsSortedByLikes {
    final posts = List<CommunityPost>.from(_currentGroupPosts);
    posts.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return posts;
  }

  List<CommunityPost> get postsSortedByComments {
    final posts = List<CommunityPost>.from(_currentGroupPosts);
    posts.sort((a, b) => b.commentCount.compareTo(a.commentCount));
    return posts;
  }

  // ==================== DEBUG METHODS ====================

  void debugPrintState() {
    print('=== CommunityProvider State ===');
    print('All Groups: ${_allGroups.length}');
    print('User Groups: ${_userGroups.length}');
    print('Current Group Posts: ${_currentGroupPosts.length}');
    print('Current Post Comments: ${_currentPostComments.length}');
    print('Selected Group: ${_selectedGroup?.name ?? 'None'}');
    print('Selected Post: ${_selectedPost?.content.substring(0, 20) ?? 'None'}...');
    print('Is Loading: $_isLoading');
    print('Is Loading Posts: $_isLoadingPosts');
    print('Is Loading Comments: $_isLoadingComments');
    print('Is Uploading: $_isUploading');
    print('Upload Progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%');
    print('Upload Status: $_uploadStatus');
    print('Error: $_error');
    print('Is Initialized: $_isInitialized');
    print('Current User ID: ${_communityService.currentUserId}');
    print('Active Subscriptions:');
    print('  - All Groups: ${_allGroupsSubscription != null}');
    print('  - User Groups: ${_userGroupsSubscription != null}');
    print('  - Posts: ${_postsSubscription != null}');
    print('  - Comments: ${_commentsSubscription != null}');
    print('================================');
  }

  Future<void> debugFirestoreConnection() async {
    await _communityService.debugFirestoreConnection();
  }

  Map<String, dynamic> getDebugInfo() {
    return {
      'allGroupsCount': _allGroups.length,
      'userGroupsCount': _userGroups.length,
      'currentPostsCount': _currentGroupPosts.length,
      'currentCommentsCount': _currentPostComments.length,
      'selectedGroup': _selectedGroup?.name,
      'selectedPost': _selectedPost?.id,
      'isLoading': _isLoading,
      'isLoadingPosts': _isLoadingPosts,
      'isLoadingComments': _isLoadingComments,
      'isUploading': _isUploading,
      'uploadProgress': _uploadProgress,
      'uploadStatus': _uploadStatus,
      'error': _error,
      'isInitialized': _isInitialized,
      'currentUserId': _communityService.currentUserId,
      'hasActiveSubscriptions': {
        'allGroups': _allGroupsSubscription != null,
        'userGroups': _userGroupsSubscription != null,
        'posts': _postsSubscription != null,
        'comments': _commentsSubscription != null,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // ==================== VALIDATION METHODS ====================

  String? validatePostContent(String content, {int maxLength = 5000}) {
    if (content.trim().isEmpty) {
      return 'กรุณาใส่เนื้อหาโพสต์';
    }
    if (content.length > maxLength) {
      return 'เนื้อหาโพสต์ยาวเกินไป (สูงสุด $maxLength ตัวอักษร)';
    }
    return null;
  }

  Future<String?> validateImages(List<XFile> imageFiles, {int maxCount = 10}) async {
    if (imageFiles.length > maxCount) {
      return 'สามารถเลือกรูปภาพได้สูงสุด $maxCount รูป';
    }

    for (var file in imageFiles) {
      if (!_isImageFile(file)) {
        return 'ไฟล์ ${file.name} ไม่ใช่รูปภาพ';
      }
      
      final fileSize = await File(file.path).length();
      if (fileSize > 50 * 1024 * 1024) { // 50MB
        return 'รูปภาพ ${file.name} มีขนาดใหญ่เกินไป (สูงสุด 50MB)';
      }
    }
    
    return null;
  }

  Future<String?> validateVideo(XFile videoFile) async {
    if (!_isVideoFile(videoFile)) {
      return 'ไฟล์ ${videoFile.name} ไม่ใช่วิดีโอ';
    }
    
    final fileSize = await File(videoFile.path).length();
    if (fileSize > 100 * 1024 * 1024) { // 100MB
      return 'วิดีโอมีขนาดใหญ่เกินไป (สูงสุด 100MB)';
    }
    
    return null;
  }

  bool _isImageFile(XFile file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  bool _isVideoFile(XFile file) {
    final extension = file.path.split('.').last.toLowerCase();
    return ['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm', 'mkv'].contains(extension);
  }

  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // ==================== BATCH OPERATIONS ====================

  Future<List<bool>> joinMultipleGroups(List<String> groupIds) async {
    final results = <bool>[];
    
    for (final groupId in groupIds) {
      try {
        final success = await joinGroup(groupId);
        results.add(success);
      } catch (e) {
        print('Error joining group $groupId in batch: $e');
        results.add(false);
      }
    }
    
    return results;
  }

  Future<List<bool>> deleteMultiplePosts(List<String> postIds, String groupId) async {
    final results = <bool>[];
    
    for (final postId in postIds) {
      try {
        final success = await deletePost(postId, groupId);
        results.add(success);
      } catch (e) {
        print('Error deleting post $postId in batch: $e');
        results.add(false);
      }
    }
    
    return results;
  }

  Future<List<bool>> addMultipleComments(List<String> contents, String postId) async {
    final results = <bool>[];
    
    for (final content in contents) {
      try {
        final success = await addComment(postId: postId, content: content);
        results.add(success);
      } catch (e) {
        print('Error adding comment in batch: $e');
        results.add(false);
      }
    }
    
    return results;
  }

  // ==================== PERFORMANCE OPTIMIZATION ====================

  void limitPostsInMemory({int maxPosts = 100}) {
    if (_currentGroupPosts.length > maxPosts) {
      _currentGroupPosts = _currentGroupPosts.take(maxPosts).toList();
      print('Limited posts in memory to $maxPosts items');
      notifyListeners();
    }
  }

  void limitCommentsInMemory({int maxComments = 200}) {
    if (_currentPostComments.length > maxComments) {
      _currentPostComments = _currentPostComments.take(maxComments).toList();
      print('Limited comments in memory to $maxComments items');
      notifyListeners();
    }
  }

  void optimizeMemoryUsage() {
    limitPostsInMemory();
    limitCommentsInMemory();
    print('Memory optimization completed');
  }

  // ==================== EXPORT/IMPORT FUNCTIONALITY ====================

  Map<String, dynamic> exportUserData() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '2.0',
      'cloudinary': true,
      'userGroups': _userGroups.map((group) => {
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'tags': group.tags,
        'memberCount': group.memberCount,
        'postCount': group.postCount,
        'isPublic': group.isPublic,
        'joinedAt': group.createdAt.toIso8601String(),
      }).toList(),
      'statistics': getUserStatistics(),
    };
  }

  Map<String, dynamic> exportGroupData(String groupId) {
    final group = findGroupById(groupId);
    if (group == null) return {};

    final posts = _selectedGroup?.id == groupId ? _currentGroupPosts : <CommunityPost>[];
    
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'version': '2.0',
      'cloudinary': true,
      'group': {
        'id': group.id,
        'name': group.name,
        'description': group.description,
        'tags': group.tags,
        'memberCount': group.memberCount,
        'postCount': group.postCount,
        'isPublic': group.isPublic,
        'createdAt': group.createdAt.toIso8601String(),
      },
      'posts': posts.map((post) => {
        'id': post.id,
        'content': post.content,
        'type': post.type.toString(),
        'imageCount': post.images.length,
        'hasVideo': post.hasVideo,
        'likeCount': post.likeCount,
        'commentCount': post.commentCount,
        'createdAt': post.createdAt.toIso8601String(),
        'authorName': post.authorName,
      }).toList(),
      'statistics': getGroupStatistics(groupId),
    };
  }

  // ==================== ADVANCED SEARCH ====================

  List<CommunityGroup> advancedSearchGroups({
    String? name,
    String? description,
    List<String>? tags,
    int? minMembers,
    int? maxMembers,
    bool? isPublic,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) {
    var results = _allGroups;

    if (name != null && name.isNotEmpty) {
      results = results.where((group) => 
        group.name.toLowerCase().contains(name.toLowerCase())
      ).toList();
    }

    if (description != null && description.isNotEmpty) {
      results = results.where((group) => 
        group.description.toLowerCase().contains(description.toLowerCase())
      ).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((group) => 
        tags.any((tag) => group.tags.any((groupTag) => 
          groupTag.toLowerCase().contains(tag.toLowerCase())
        ))
      ).toList();
    }

    if (minMembers != null) {
      results = results.where((group) => group.memberCount >= minMembers).toList();
    }

    if (maxMembers != null) {
      results = results.where((group) => group.memberCount <= maxMembers).toList();
    }

    if (isPublic != null) {
      results = results.where((group) => group.isPublic == isPublic).toList();
    }

    if (createdAfter != null) {
      results = results.where((group) => group.createdAt.isAfter(createdAfter)).toList();
    }

    if (createdBefore != null) {
      results = results.where((group) => group.createdAt.isBefore(createdBefore)).toList();
    }

    return results;
  }

  List<CommunityPost> advancedSearchPosts({
    String? content,
    String? authorName,
    PostType? type,
    int? minLikes,
    int? maxLikes,
    int? minComments,
    int? maxComments,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? hasImages,
    bool? hasVideo,
  }) {
    var results = _currentGroupPosts;

    if (content != null && content.isNotEmpty) {
      results = results.where((post) => 
        post.content.toLowerCase().contains(content.toLowerCase())
      ).toList();
    }

    if (authorName != null && authorName.isNotEmpty) {
      results = results.where((post) => 
        post.authorName.toLowerCase().contains(authorName.toLowerCase())
      ).toList();
    }

    if (type != null) {
      results = results.where((post) => post.type == type).toList();
    }

    if (minLikes != null) {
      results = results.where((post) => post.likeCount >= minLikes).toList();
    }

    if (maxLikes != null) {
      results = results.where((post) => post.likeCount <= maxLikes).toList();
    }

    if (minComments != null) {
      results = results.where((post) => post.commentCount >= minComments).toList();
    }

    if (maxComments != null) {
      results = results.where((post) => post.commentCount <= maxComments).toList();
    }

    if (createdAfter != null) {
      results = results.where((post) => post.createdAt.isAfter(createdAfter)).toList();
    }

    if (createdBefore != null) {
      results = results.where((post) => post.createdAt.isBefore(createdBefore)).toList();
    }

    if (hasImages != null) {
      results = results.where((post) => post.hasImages == hasImages).toList();
    }

    if (hasVideo != null) {
      results = results.where((post) => post.hasVideo == hasVideo).toList();
    }

    return results;
  }

  // ==================== ANALYTICS ====================

  Map<String, dynamic> getAnalytics() {
    final now = DateTime.now();
    final last7Days = now.subtract(Duration(days: 7));
    final last30Days = now.subtract(Duration(days: 30));

    final recentPosts = _currentGroupPosts.where((post) => 
      post.createdAt.isAfter(last7Days)
    ).toList();

    final monthlyPosts = _currentGroupPosts.where((post) => 
      post.createdAt.isAfter(last30Days)
    ).toList();

    final recentComments = _currentPostComments.where((comment) => 
      comment.createdAt.isAfter(last7Days)
    ).toList();

    return {
      'totalGroups': _allGroups.length,
      'joinedGroups': _userGroups.length,
      'totalPosts': _currentGroupPosts.length,
      'recentPosts': recentPosts.length,
      'monthlyPosts': monthlyPosts.length,
      'totalComments': _currentPostComments.length,
      'recentComments': recentComments.length,
      'averageLikesPerPost': _currentGroupPosts.isNotEmpty 
          ? (_currentGroupPosts.fold<int>(0, (sum, post) => sum + post.likeCount) / _currentGroupPosts.length).round()
          : 0,
      'averageCommentsPerPost': _currentGroupPosts.isNotEmpty 
          ? (_currentGroupPosts.fold<int>(0, (sum, post) => sum + post.commentCount) / _currentGroupPosts.length).round()
          : 0,
      'mostActiveGroup': _userGroups.isNotEmpty 
          ? _userGroups.reduce((a, b) => a.postCount > b.postCount ? a : b).name
          : null,
      'postTypeDistribution': _getPostTypeDistribution(),
      'engagementRate': _calculateEngagementRate(),
      'growthMetrics': {
        'last7Days': recentPosts.length,
        'last30Days': monthlyPosts.length,
      },
    };
  }

  Map<String, int> _getPostTypeDistribution() {
    final distribution = <String, int>{};
    
    for (final post in _currentGroupPosts) {
      final typeKey = post.type.toString().split('.').last;
      distribution[typeKey] = (distribution[typeKey] ?? 0) + 1;
    }
    
    return distribution;
  }

  double _calculateEngagementRate() {
    if (_currentGroupPosts.isEmpty) return 0.0;
    
    final totalEngagement = _currentGroupPosts.fold<int>(0, (sum, post) => 
      sum + post.likeCount + post.commentCount
    );
    
    return totalEngagement / _currentGroupPosts.length;
  }

  // ==================== NOTIFICATION HELPERS ====================

  List<Map<String, dynamic>> getPendingNotifications() {
    final notifications = <Map<String, dynamic>>[];
    final userId = _communityService.currentUserId;
    
    if (userId == null) return notifications;

    // New likes on user's posts
    for (final post in _currentGroupPosts) {
      if (post.authorId == userId && post.likeCount > 0) {
        notifications.add({
          'type': 'post_liked',
          'postId': post.id,
          'content': post.content.substring(0, 50),
          'likeCount': post.likeCount,
          'timestamp': post.updatedAt,
        });
      }
    }

    // New comments on user's posts
    for (final post in _currentGroupPosts) {
      if (post.authorId == userId && post.commentCount > 0) {
        notifications.add({
          'type': 'post_commented',
          'postId': post.id,
          'content': post.content.substring(0, 50),
          'commentCount': post.commentCount,
          'timestamp': post.updatedAt,
        });
      }
    }

    // Sort by timestamp
    notifications.sort((a, b) => 
      (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime)
    );

    return notifications.take(20).toList();
  }

  // ==================== CLEANUP ====================

  void cleanup() {
    print('Cleaning up CommunityProvider...');
    optimizeMemoryUsage();
    _clearError();
  }
}