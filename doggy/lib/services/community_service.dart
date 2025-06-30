import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/community_models.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserName => _auth.currentUser?.displayName ?? _auth.currentUser?.email;
  
  // Getter สำหรับ FirebaseAuth (เพื่อให้ CommunityProvider ใช้งานได้)
  FirebaseAuth get auth => _auth;

  // ==================== GROUP METHODS ====================

  // สร้างกลุ่มใหม่
  Future<String?> createGroup(CommunityGroup group) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // สร้าง group ใหม่โดยไม่ใช้ copyWith
      final newGroup = CommunityGroup(
        id: '', // จะถูกแทนที่ด้วย document ID
        name: group.name,
        description: group.description,
        tags: group.tags,
        memberIds: [currentUserId!],
        memberCount: 1,
        postCount: group.postCount,
        isPublic: group.isPublic,
        coverImage: group.coverImage,
        createdBy: currentUserId!,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('community_groups').add(newGroup.toFirestore());

      // เพิ่มผู้สร้างเป็นสมาชิกแรก
      await _addGroupMember(docRef.id, currentUserId!, 'admin');

      return docRef.id;
    } catch (e) {
      print('Error creating group: $e');
      return null;
    }
  }

  // ดึงกลุ่มทั้งหมด - Real-time
  Stream<List<CommunityGroup>> getAllGroups() {
    return _firestore
        .collection('community_groups')
        .where('isPublic', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommunityGroup.fromFirestore(doc))
              .toList();
        });
  }

  // ดึงกลุ่มของผู้ใช้ - Real-time
  Stream<List<CommunityGroup>> getUserGroups() {
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('community_groups')
        .where('memberIds', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommunityGroup.fromFirestore(doc))
              .toList();
        });
  }

  // ค้นหากลุ่ม
  Future<List<CommunityGroup>> searchGroups(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('community_groups')
          .where('isPublic', isEqualTo: true)
          .get();

      return querySnapshot.docs
          .map((doc) => CommunityGroup.fromFirestore(doc))
          .where((group) =>
              group.name.toLowerCase().contains(query.toLowerCase()) ||
              group.description.toLowerCase().contains(query.toLowerCase()) ||
              group.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase())))
          .toList();
    } catch (e) {
      print('Error searching groups: $e');
      return [];
    }
  }

  // เข้าร่วมกลุ่ม - ใช้ Transaction เพื่อความปลอดภัย
  Future<bool> joinGroup(String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final result = await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) throw Exception('Group not found');

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (memberIds.contains(currentUserId)) {
          throw Exception('Already a member');
        }

        memberIds.add(currentUserId!);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (result) {
        // เพิ่มข้อมูลสมาชิก
        await _addGroupMember(groupId, currentUserId!, 'member');
      }

      return result;
    } catch (e) {
      print('Error joining group: $e');
      return false;
    }
  }

  // ออกจากกลุ่ม - ใช้ Transaction เพื่อความปลอดภัย
  Future<bool> leaveGroup(String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final result = await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) throw Exception('Group not found');

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (!memberIds.contains(currentUserId)) {
          throw Exception('Not a member');
        }

        memberIds.remove(currentUserId);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      if (result) {
        // ลบข้อมูลสมาชิก
        await _removeGroupMember(groupId, currentUserId!);
      }

      return result;
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  // เพิ่มสมาชิกในกลุ่ม
  Future<void> _addGroupMember(String groupId, String userId, String role) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .set(GroupMember(
          userId: userId,
          userEmail: currentUserEmail ?? '',
          userName: currentUserName ?? '',
          role: role,
          joinedAt: DateTime.now(),
        ).toFirestore());
  }

  // ลบสมาชิกจากกลุ่ม
  Future<void> _removeGroupMember(String groupId, String userId) async {
    await _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .doc(userId)
        .delete();
  }

  // ดึงสมาชิกในกลุ่ม - Real-time
  Stream<List<GroupMember>> getGroupMembers(String groupId) {
    return _firestore
        .collection('community_groups')
        .doc(groupId)
        .collection('members')
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupMember.fromFirestore(doc))
              .toList();
        });
  }

  // ==================== POST METHODS ====================

  // สร้างโพสต์ใหม่
  Future<String?> createPost(CommunityPost post) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // สร้าง post ใหม่โดยไม่ใช้ copyWith
      final newPost = CommunityPost(
        id: '', // จะถูกแทนที่ด้วย document ID
        groupId: post.groupId,
        authorId: currentUserId!,
        authorName: currentUserName ?? 'Unknown',
        authorAvatar: _auth.currentUser?.photoURL,
        content: post.content,
        imageUrls: post.imageUrls,
        videoUrl: post.videoUrl,
        type: post.type,
        likedBy: [],
        likeCount: 0,
        commentCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('community_posts').add(newPost.toFirestore());

      // อัพเดทจำนวนโพสต์ในกลุ่ม
      await _updateGroupPostCount(post.groupId, 1);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
    }
  }

  // ดึงโพสต์ในกลุ่ม - Real-time
  Stream<List<CommunityPost>> getGroupPosts(String groupId) {
    return _firestore
        .collection('community_posts')
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => CommunityPost.fromFirestore(doc))
              .toList();
        });
  }

  // ลบโพสต์
  Future<bool> deletePost(String postId, String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // ตรวจสอบสิทธิ์ในการลบ
      final postDoc = await _firestore.collection('community_posts').doc(postId).get();
      if (!postDoc.exists) return false;

      final postData = postDoc.data()!;
      final postAuthorId = postData['authorId'];

      // ตรวจสอบว่าเป็นเจ้าของโพสต์หรือ admin
      if (postAuthorId != currentUserId) {
        final memberDoc = await _firestore
            .collection('community_groups')
            .doc(groupId)
            .collection('members')
            .doc(currentUserId)
            .get();
        
        if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
          throw Exception('No permission to delete this post');
        }
      }

      await _firestore.collection('community_posts').doc(postId).delete();

      // อัพเดทจำนวนโพสต์ในกลุ่ม
      await _updateGroupPostCount(groupId, -1);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

  // กดไลค์โพสต์ - แก้ไข Transaction เพื่อ Real-time
  Future<bool> togglePostLike(String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final result = await _firestore.runTransaction((transaction) async {
        final postRef = _firestore.collection('community_posts').doc(postId);
        final postSnapshot = await transaction.get(postRef);

        if (!postSnapshot.exists) throw Exception('Post not found');

        final postData = postSnapshot.data()!;
        final likedBy = List<String>.from(postData['likedBy'] ?? []);
        
        bool isCurrentlyLiked = likedBy.contains(currentUserId);
        
        if (isCurrentlyLiked) {
          // Unlike
          likedBy.remove(currentUserId);
        } else {
          // Like
          likedBy.add(currentUserId!);
        }

        transaction.update(postRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      return result;
    } catch (e) {
      print('Error toggling post like: $e');
      return false;
    }
  }

  // อัพเดทจำนวนโพสต์ในกลุ่ม
  Future<void> _updateGroupPostCount(String groupId, int change) async {
    await _firestore.collection('community_groups').doc(groupId).update({
      'postCount': FieldValue.increment(change),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== COMMENT METHODS ====================

  // เพิ่มคอมเมนต์
  Future<String?> addComment(PostComment comment) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // สร้าง comment ใหม่โดยไม่ใช้ copyWith
      final newComment = PostComment(
        id: '', // จะถูกแทนที่ด้วย document ID
        postId: comment.postId,
        authorId: currentUserId!,
        authorName: currentUserName ?? 'Unknown',
        authorAvatar: _auth.currentUser?.photoURL,
        content: comment.content,
        likedBy: [],
        likeCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: comment.parentCommentId,
      );

      final docRef = await _firestore.collection('post_comments').add(newComment.toFirestore());

      // อัพเดทจำนวนคอมเมนต์ในโพสต์
      await _updatePostCommentCount(comment.postId, 1);

      return docRef.id;
    } catch (e) {
      print('Error adding comment: $e');
      return null;
    }
  }

  // ดึงคอมเมนต์ของโพสต์ - Real-time
  Stream<List<PostComment>> getPostComments(String postId) {
    return _firestore
        .collection('post_comments')
        .where('postId', isEqualTo: postId)
        .where('parentCommentId', isNull: true) // เฉพาะคอมเมนต์หลัก
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PostComment.fromFirestore(doc))
              .toList();
        });
  }

  // ลบคอมเมนต์
  Future<bool> deleteComment(String commentId, String postId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // ตรวจสอบสิทธิ์ในการลบ
      final commentDoc = await _firestore.collection('post_comments').doc(commentId).get();
      if (!commentDoc.exists) return false;

      final commentData = commentDoc.data()!;
      final commentAuthorId = commentData['authorId'];

      if (commentAuthorId != currentUserId) {
        throw Exception('No permission to delete this comment');
      }

      await _firestore.collection('post_comments').doc(commentId).delete();

      // อัพเดทจำนวนคอมเมนต์ในโพสต์
      await _updatePostCommentCount(postId, -1);

      return true;
    } catch (e) {
      print('Error deleting comment: $e');
      return false;
    }
  }

  // กดไลค์คอมเมนต์ - แก้ไข Transaction เพื่อ Real-time
  Future<bool> toggleCommentLike(String commentId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final result = await _firestore.runTransaction((transaction) async {
        final commentRef = _firestore.collection('post_comments').doc(commentId);
        final commentSnapshot = await transaction.get(commentRef);

        if (!commentSnapshot.exists) throw Exception('Comment not found');

        final commentData = commentSnapshot.data()!;
        final likedBy = List<String>.from(commentData['likedBy'] ?? []);
        
        bool isCurrentlyLiked = likedBy.contains(currentUserId);
        
        if (isCurrentlyLiked) {
          // Unlike
          likedBy.remove(currentUserId);
        } else {
          // Like
          likedBy.add(currentUserId!);
        }

        transaction.update(commentRef, {
          'likedBy': likedBy,
          'likeCount': likedBy.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });

      return result;
    } catch (e) {
      print('Error toggling comment like: $e');
      return false;
    }
  }

  // อัพเดทจำนวนคอมเมนต์ในโพสต์
  Future<void> _updatePostCommentCount(String postId, int change) async {
    await _firestore.collection('community_posts').doc(postId).update({
      'commentCount': FieldValue.increment(change),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ==================== FILE UPLOAD METHODS ====================

  // อัพโหลดรูปภาพ
  Future<String?> uploadImage(File imageFile, String folder) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$currentUserId/$fileName');
      
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // อัพโหลดวิดีโอ
  Future<String?> uploadVideo(File videoFile, String folder) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${videoFile.path.split('/').last}';
      final ref = _storage.ref().child('$folder/$currentUserId/$fileName');
      
      final uploadTask = ref.putFile(videoFile);
      final snapshot = await uploadTask;
      
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  // ลบไฟล์จาก Storage
  Future<bool> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }
}