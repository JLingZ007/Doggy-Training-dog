// services/community_service.dart - อัพเดทสำหรับ Base64 Images
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserName => _auth.currentUser?.displayName ?? _auth.currentUser?.email?.split('@').first ?? 'Unknown User';
  
  FirebaseAuth get auth => _auth;

  // ==================== IMAGE UTILITIES ====================

  /// แปลงไฟล์รูปภาพเป็น Base64
  Future<String?> convertImageToBase64(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // เพิ่ม data URL prefix สำหรับ image
      final mimeType = _getMimeType(imageFile.path);
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Error converting image to base64: $e');
      return null;
    }
  }

  /// แปลงไฟล์วิดีโอเป็น Base64 (สำหรับไฟล์เล็ก)
  Future<String?> convertVideoToBase64(File videoFile) async {
    try {
      final fileSize = await videoFile.length();
      
      // จำกัดขนาดวิดีโอ (10MB สำหรับ Base64)
      if (fileSize > 10 * 1024 * 1024) {
        print('Video file too large for Base64: ${fileSize / (1024 * 1024)} MB');
        return null;
      }

      final bytes = await videoFile.readAsBytes();
      final base64String = base64Encode(bytes);
      
      // เพิ่ม data URL prefix สำหรับ video
      final mimeType = _getMimeType(videoFile.path);
      return 'data:$mimeType;base64,$base64String';
    } catch (e) {
      print('Error converting video to base64: $e');
      return null;
    }
  }

  /// ดึง MIME type จาก file extension
  String _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/avi';
      default:
        return 'application/octet-stream';
    }
  }

  /// บีบอัดรูปภาพก่อนแปลงเป็น Base64
  Future<String?> compressAndConvertToBase64(File imageFile, {int quality = 70}) async {
    try {
      // สำหรับ Flutter Web หรือ Mobile ที่ต้องการบีบอัด
      // ต้องใช้ package เพิ่มเติม เช่น image_compression
      
      // สำหรับตอนนี้ ใช้วิธีพื้นฐาน
      return await convertImageToBase64(imageFile);
    } catch (e) {
      print('Error compressing and converting image: $e');
      return null;
    }
  }

  // ==================== GROUP METHODS (เดิม) ====================

  Future<String?> createGroup(CommunityGroup group) async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        throw Exception('User not authenticated');
      }

      print('Creating group: ${group.name}');
      
      final groupData = {
        'name': group.name,
        'description': group.description,
        'tags': group.tags,
        'memberIds': [currentUserId!],
        'memberCount': 1,
        'postCount': 0,
        'isPublic': group.isPublic,
        'coverImage': group.coverImage,
        'coverImageBase64': group.coverImageBase64,
        'createdBy': currentUserId!,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('community_groups').add(groupData);
      print('Group created with ID: ${docRef.id}');

      await _addGroupMember(docRef.id, currentUserId!, 'admin');
      print('Added creator as admin member');

      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  Stream<List<CommunityGroup>> getAllGroups() {
    print('Getting all public groups stream...');
    
    return _firestore
        .collection('community_groups')
        .where('isPublic', isEqualTo: true)
        .snapshots()
        .handleError((error) {
          print('Error in getAllGroups stream: $error');
        })
        .map((snapshot) {
          print('Received ${snapshot.docs.length} groups from Firestore');
          
          var groups = snapshot.docs.map((doc) {
            try {
              final group = CommunityGroup.fromFirestore(doc);
              print('Parsed group: ${group.name} (${group.id})');
              return group;
            } catch (e) {
              print('Error parsing group ${doc.id}: $e');
              print('Group data: ${doc.data()}');
              rethrow;
            }
          }).toList();
          
          // เรียงลำดับใน Dart แทน Firestore
          groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          return groups;
        });
  }

  Stream<List<CommunityGroup>> getUserGroups() {
    if (currentUserId == null) {
      print('No current user, returning empty stream');
      return Stream.value([]);
    }

    print('Getting user groups stream for user: $currentUserId');
    
    return _firestore
        .collection('community_groups')
        .where('memberIds', arrayContains: currentUserId)
        .snapshots()
        .handleError((error) {
          print('Error in getUserGroups stream: $error');
        })
        .map((snapshot) {
          print('User has ${snapshot.docs.length} groups');
          
          var groups = snapshot.docs.map((doc) {
            try {
              final group = CommunityGroup.fromFirestore(doc);
              print('User group: ${group.name} (${group.id})');
              return group;
            } catch (e) {
              print('Error parsing user group ${doc.id}: $e');
              rethrow;
            }
          }).toList();
          
          // เรียงลำดับใน Dart แทน Firestore
          groups.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          
          return groups;
        });
  }

  Future<List<CommunityGroup>> searchGroups(String query) async {
    try {
      print('Searching groups with query: $query');
      
      final querySnapshot = await _firestore
          .collection('community_groups')
          .where('isPublic', isEqualTo: true)
          .get();

      final results = querySnapshot.docs
          .map((doc) => CommunityGroup.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(query.toLowerCase()) ||
              group.description.toLowerCase().contains(query.toLowerCase()) ||
              group.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
          
      print('Found ${results.length} groups matching query');
      return results;
    } catch (e) {
      print('Error searching groups: $e');
      return [];
    }
  }

  Future<bool> joinGroup(String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('User $currentUserId joining group $groupId');

      return await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          print('Group $groupId not found');
          throw Exception('Group not found');
        }

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (memberIds.contains(currentUserId)) {
          print('User $currentUserId already a member of group $groupId');
          return true;
        }

        memberIds.add(currentUserId!);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated group $groupId with new member count: ${memberIds.length}');
        return true;
      }).then((result) async {
        if (result) {
          await _addGroupMember(groupId, currentUserId!, 'member');
          print('Added member data for user $currentUserId in group $groupId');
        }
        return result;
      });
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  Future<bool> leaveGroup(String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('User $currentUserId leaving group $groupId');

      return await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          print('Group $groupId not found');
          throw Exception('Group not found');
        }

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (!memberIds.contains(currentUserId)) {
          print('User $currentUserId not a member of group $groupId');
          return true;
        }

        memberIds.remove(currentUserId);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated group $groupId, removed member, new count: ${memberIds.length}');
        return true;
      }).then((result) async {
        if (result) {
          await _removeGroupMember(groupId, currentUserId!);
          print('Removed member data for user $currentUserId from group $groupId');
        }
        return result;
      });
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  Future<void> _addGroupMember(String groupId, String userId, String role) async {
    try {
      final memberData = {
        'userId': userId,
        'userEmail': currentUserEmail ?? '',
        'userName': currentUserName ?? '',
        'userAvatar': _auth.currentUser?.photoURL,
        'userAvatarBase64': null, // สามารถเพิ่มภายหลัง
        'role': role,
        'joinedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .set(memberData);
          
      print('Added member data for $userId in group $groupId with role $role');
    } catch (e) {
      print('Error adding group member: $e');
    }
  }

  Future<void> _removeGroupMember(String groupId, String userId) async {
    try {
      await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .delete();
          
      print('Removed member data for $userId from group $groupId');
    } catch (e) {
      print('Error removing group member: $e');
    }
  }

  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    print('Getting members for group: $groupId');
    
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .snapshots()
        .handleError((error) {
          print('Error in getGroupMembers stream: $error');
        })
        .map((snapshot) {
          print('Group $groupId has ${snapshot.docs.length} members');
          
          var members = snapshot.docs
              .map((doc) => GroupMember.fromFirestore(doc))
              .toList();
              
          // เรียงลำดับตาม joinedAt
          members.sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
          
          return members;
        });
  }

  // ==================== POST METHODS (อัพเดทสำหรับ Base64) ====================

  Future<String?> createPost(CommunityPost post) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Creating post in group: ${post.groupId}');

      final postData = {
        'groupId': post.groupId,
        'authorId': currentUserId!,
        'authorName': currentUserName ?? '',
        'authorAvatar': _auth.currentUser?.photoURL,
        'authorAvatarBase64': null, // สามารถเพิ่มภายหลัง
        'content': post.content,
        'imageUrls': post.imageUrls,
        'imageBase64s': post.imageBase64s,
        'videoUrl': post.videoUrl,
        'videoBase64': post.videoBase64,
        'type': post.type.toString().split('.').last,
        'likedBy': <String>[],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('community_posts').add(postData);
      print('Post created with ID: ${docRef.id}');

      // อัพเดทจำนวนโพสต์ในกลุ่ม - แก้ไขให้ไม่มี permission error
      await _updateGroupPostCountSafely(post.groupId, 1);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  /// อัพเดท postCount แบบปลอดภัย
  Future<void> _updateGroupPostCountSafely(String groupId, int change) async {
    try {
      // ใช้ transaction เพื่อความปลอดภัย
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          print('Group $groupId not found for post count update');
          return;
        }

        final groupData = groupSnapshot.data()!;
        final currentPostCount = groupData['postCount'] ?? 0;
        final newPostCount = (currentPostCount + change).clamp(0, double.infinity).toInt();

        transaction.update(groupRef, {
          'postCount': newPostCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated group $groupId post count to $newPostCount (changed by $change)');
      });
    } catch (e) {
      print('Error updating group post count safely: $e');
      // ไม่ throw error เพื่อไม่ให้การสร้างโพสต์ล้มเหลว
    }
  }

  Stream<List<CommunityPost>> getGroupPosts(String groupId) {
    print('Getting posts for group: $groupId');
    
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .snapshots()
        .handleError((error) {
          print('Error in getGroupPosts stream: $error');
        })
        .map((snapshot) {
          print('Group $groupId has ${snapshot.docs.length} posts');
          
          var posts = snapshot.docs.map((doc) {
            try {
              final post = CommunityPost.fromFirestore(doc);
              print('Post: ${post.content.substring(0, post.content.length > 30 ? 30 : post.content.length)}...');
              return post;
            } catch (e) {
              print('Error parsing post ${doc.id}: $e');
              print('Post data: ${doc.data()}');
              rethrow;
            }
          }).toList();
          
          // เรียงลำดับตาม createdAt
          posts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return posts;
        });
  }

  Future<bool> deletePost(String postId, String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Deleting post: $postId');

      final postDoc = await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) {
        print('Post $postId not found');
        return false;
      }

      final postData = postDoc.data()!;
      final postAuthorId = postData['authorId'];

      if (postAuthorId != currentUserId) {
        final memberDoc = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('members')
            .doc(currentUserId)
            .get();
        
        if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
          print('User $currentUserId has no permission to delete post $postId');
          throw Exception('No permission to delete this post');
        }
      }

      await _firestore.collection('community_posts').doc(postId).delete();
      print('Post $postId deleted successfully');

      await _updateGroupPostCountSafely(groupId, -1);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  Future<bool> togglePostLike(String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Toggling like for post: $postId by user: $currentUserId');

      return await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('community_posts').doc(postId);
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          print('Post $postId not found');
          throw Exception('Post not found');
        }

        final postData = postSnapshot.data()!;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);
        
        bool isCurrentlyLiked = likedBy.contains(currentUserId);
        
        if (isCurrentlyLiked) {
          likedBy.remove(currentUserId);
          print('User $currentUserId unliked post $postId');
        } else {
          likedBy.add(currentUserId!);
          print('User $currentUserId liked post $postId');
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated post $postId like count: ${likedBy.length}');
        return true;
      });
    } catch (e) {
      print('Error toggling post like: $e');
      return false;
    }
  }

  // ==================== COMMENT METHODS (อัพเดทสำหรับ Base64) ====================

  Future<String?> addComment(PostComment comment) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Adding comment to post: ${comment.postId}');

      final commentData = {
        'postId': comment.postId,
        'authorId': currentUserId!,
        'authorName': currentUserName ?? '',
        'authorAvatar': _auth.currentUser?.photoURL,
        'authorAvatarBase64': null, // สามารถเพิ่มภายหลัง
        'content': comment.content,
        'likedBy': <String>[],
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'parentCommentId': comment.parentCommentId,
      };

      final docRef = await _firestore.collection('post_comments').add(commentData);
      print('Comment created with ID: ${docRef.id}');

      await _updatePostCommentCountSafely(comment.postId, 1);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  /// อัพเดท commentCount แบบปลอดภัย
  Future<void> _updatePostCommentCountSafely(String postId, int change) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('community_posts').doc(postId);
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) {
          print('Post $postId not found for comment count update');
          return;
        }

        final postData = postSnapshot.data()!;
        final currentCommentCount = postData['commentCount'] ?? 0;
        final newCommentCount = (currentCommentCount + change).clamp(0, double.infinity).toInt();

        transaction.update(postRef, {
          'commentCount': newCommentCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated post $postId comment count to $newCommentCount (changed by $change)');
      });
    } catch (e) {
      print('Error updating post comment count safely: $e');
    }
  }

  Stream<List<PostComment>> getPostComments(String postId) {
    print('Getting comments for post: $postId');
    
    return _firestore
        .collection('post_comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true)
        .snapshots()
        .handleError((error) {
          print('Error in getPostComments stream: $error');
        })
        .map((snapshot) {
          print('Post $postId has ${snapshot.docs.length} comments');
          
          var comments = snapshot.docs.map((doc) {
            try {
              return PostComment.fromFirestore(doc);
            } catch (e) {
              print('Error parsing comment ${doc.id}: $e');
              rethrow;
            }
          }).toList();
          
          // เรียงลำดับตาม createdAt
          comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          return comments;
        });
  }

  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Deleting comment: $commentId');

      final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
      if (!commentDoc.exists) {
        print('Comment $commentId not found');
        return false;
      }

      final commentData = commentDoc.data()!;
      final commentAuthorId = commentData['authorId'];

      if (commentAuthorId != currentUserId) {
        print('User $currentUserId has no permission to delete comment $commentId');
        throw Exception('No permission to delete this comment');
      }

      await _firestore.collection('post_comments').doc(commentId).delete();
      print('Comment $commentId deleted successfully');

      await _updatePostCommentCountSafely(postId, -1);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  Future<bool> toggleCommentLike(String commentId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Toggling like for comment: $commentId by user: $currentUserId');

      return await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentSnapshot = await transaction.get(commentRef);

        if (!commentSnapshot.exists) {
          print('Comment $commentId not found');
          throw Exception('Comment not found');
        }

        final commentData = commentSnapshot.data()!;
        final likedBy = List<String>.from(commentData['likedBy'] ?? []);
        
        bool isCurrentlyLiked = likedBy.contains(currentUserId);
        
        if (isCurrentlyLiked) {
          likedBy.remove(currentUserId);
          print('User $currentUserId unliked comment $commentId');
        } else {
          likedBy.add(currentUserId!);
          print('User $currentUserId liked comment $commentId');
        }

        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('Updated comment $commentId like count: ${likedBy.length}');
        return true;
      });
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  // ==================== FILE UPLOAD METHODS (เก็บไว้เผื่อใช้) ====================

  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Uploading image to $folder');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$currentUserId/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<String?> uploadVideo(File videoFile, String folder) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      print('Uploading video to $folder');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$currentUserId/$fileName');
      
      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('Video uploaded successfully: $downloadUrl');
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      print('File deleted successfully: $url');
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  // ==================== DEBUG METHODS ====================
  
  Future<void> debugFirestoreConnection() async {
    try {
      print('=== Debug Firestore Connection ===');
      print('Current User ID: $currentUserId');
      print('Current User Email: $currentUserEmail');
      print('Current User Name: $currentUserName');
      
      final testQuery = await _firestore.collection('community_groups').limit(1).get();
      print('Firestore connection: ${testQuery.docs.length >= 0 ? 'SUCCESS' : 'FAILED'}');
      
      final groupsSnapshot = await _firestore.collection('community_groups').count().get();
      print('Total groups in Firestore: ${groupsSnapshot.count}');
      
      final postsSnapshot = await _firestore.collection('community_posts').count().get();
      print('Total posts in Firestore: ${postsSnapshot.count}');
      
      print('=== End Debug ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }
}