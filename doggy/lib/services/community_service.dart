// community_service.dart - แก้ไข parameter names ให้ตรงกับ CloudinaryService
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/community_models.dart';
import 'cloudinary_service.dart';

class CommunityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;
  String? get currentUserEmail => _auth.currentUser?.email;
  String? get currentUserName => _auth.currentUser?.displayName ?? 
      _auth.currentUser?.email?.split('@').first ?? 'Unknown User';
  
  FirebaseAuth get auth => _auth;

  // ==================== GROUP METHODS ====================

  Future<String?> createGroup(CommunityGroup group) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      print('Creating group: ${group.name}');
      
      // อัปโหลดรูป cover ไป Cloudinary (ถ้ามี)
      String? coverImageUrl;
      String? coverImagePublicId;
      
      if (group.coverImageFile != null) {
        print('Uploading group cover image to Cloudinary...');
        
        final uploadResult = await CloudinaryService.uploadImage(
          imageFile: group.coverImageFile!,
          folder: 'community_groups/covers',
          customTags: {
            'category': 'group_cover',
            'user': currentUserId!,
          },
          autoOptimize: true,
          maxWidth: 1200,
          maxHeight: 400,
        );

        if (uploadResult['success'] == true) {
          coverImageUrl = uploadResult['url'];
          coverImagePublicId = uploadResult['public_id'];
          print('Group cover uploaded successfully: $coverImageUrl');
        } else {
          throw Exception('Failed to upload group cover: ${uploadResult['error']}');
        }
      }
      
      final groupData = {
        'name': group.name,
        'description': group.description,
        'tags': group.tags,
        'memberIds': [currentUserId!],
        'memberCount': 1,
        'postCount': 0,
        'isPublic': group.isPublic,
        'coverImageUrl': coverImageUrl,
        'coverImagePublicId': coverImagePublicId,
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

  // ==================== POST METHODS WITH FIXED CLOUDINARY TAGS ====================

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
            'category': 'post_image',
            'user': currentUserId!,
            'group': groupId,
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
            'category': 'post_video',
            'user': currentUserId!,
            'group': groupId,
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
      await updateGroupPostCount(groupId, 1);

      return docRef.id;
    } catch (e) {
      print('Error creating post: $e');
      return null;
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
            'category': 'post_image',
            'user': currentUserId!,
            'post': postId,
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
            'category': 'post_video',
            'user': currentUserId!,
            'post': postId,
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

  Future<bool> updateGroup({
    required String groupId,
    String? name,
    String? description,
    List<String>? tags,
    XFile? newCoverImage,
    bool removeCoverImage = false,
  }) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // ตรวจสอบสิทธิ์
      final memberDoc = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('members')
          .doc(currentUserId)
          .get();
      
      if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
        throw Exception('No permission to update this group');
      }

      Map<String, dynamic> updateData = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (tags != null) updateData['tags'] = tags;

      // จัดการรูป cover
      final groupDoc = await _firestore.collection('community_groups').doc(groupId).get();
      final groupData = groupDoc.data()!;
      final currentCoverPublicId = groupData['coverImagePublicId'];

      if (removeCoverImage && currentCoverPublicId != null) {
        // ลบรูปเก่า
        await CloudinaryService.deleteImage(currentCoverPublicId);
        updateData['coverImageUrl'] = null;
        updateData['coverImagePublicId'] = null;
      } else if (newCoverImage != null) {
        // ลบรูปเก่า (ถ้ามี)
        if (currentCoverPublicId != null) {
          await CloudinaryService.deleteImage(currentCoverPublicId);
        }

        // อัปโหลดรูปใหม่
        final uploadResult = await CloudinaryService.uploadImage(
          imageFile: newCoverImage,
          folder: 'community_groups/covers',
          customTags: {
            'category': 'group_cover',
            'user': currentUserId!,
            'group': groupId,
          },
          autoOptimize: true,
          maxWidth: 1200,
          maxHeight: 400,
        );

        if (uploadResult['success'] == true) {
          updateData['coverImageUrl'] = uploadResult['url'];
          updateData['coverImagePublicId'] = uploadResult['public_id'];
        }
      }

      await _firestore.collection('community_groups').doc(groupId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating group: $e');
      return false;
    }
  }

  // ==================== OTHER METHODS ====================

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
              return CommunityGroup.fromFirestore(doc);
            } catch (e) {
              print('Error parsing group ${doc.id}: $e');
              rethrow;
            }
          }).toList();
          
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
              return CommunityGroup.fromFirestore(doc);
            } catch (e) {
              print('Error parsing user group ${doc.id}: $e');
              rethrow;
            }
          }).toList();
          
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
          throw Exception('Group not found');
        }

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (memberIds.contains(currentUserId)) {
          return true;
        }

        memberIds.add(currentUserId!);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }).then((result) async {
        if (result) {
          await _addGroupMember(groupId, currentUserId!, 'member');
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

      return await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) {
          throw Exception('Group not found');
        }

        final groupData = groupSnapshot.data()!;
        final memberIds = List<String>.from(groupData['memberIds'] ?? []);
        
        if (!memberIds.contains(currentUserId)) {
          return true;
        }

        memberIds.remove(currentUserId);
        
        transaction.update(groupRef, {
          'memberIds': memberIds,
          'memberCount': memberIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      }).then((result) async {
        if (result) {
          await _removeGroupMember(groupId, currentUserId!);
        }
        return result;
      });
    } catch (e) {
      print('Error leaving group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    try {
      if (currentUserId == null) throw Exception('User not authenticated');

      // ตรวจสอบสิทธิ์
      final memberDoc = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('members')
          .doc(currentUserId)
          .get();
      
      if (!memberDoc.exists || memberDoc.data()?['role'] != 'admin') {
        throw Exception('No permission to delete this group');
      }

      final groupDoc = await _firestore.collection('community_groups').doc(groupId).get();
      if (!groupDoc.exists) {
        throw Exception('Group not found');
      }

      final groupData = groupDoc.data()!;

      // ลบรูป cover ใน Cloudinary
      final coverImagePublicId = groupData['coverImagePublicId'];
      if (coverImagePublicId != null) {
        await CloudinaryService.deleteImage(coverImagePublicId);
      }

      // ลบโพสต์ทั้งหมดในกลุ่ม
      final postsSnapshot = await _firestore
          .collection('community_posts')
          .where('groupId', isEqualTo: groupId)
          .get();

      for (final postDoc in postsSnapshot.docs) {
        await deletePost(postDoc.id, groupId);
      }

      // ลบ members collection
      final membersSnapshot = await _firestore
          .collection('community_groups')
          .doc(groupId)
          .collection('members')
          .get();

      final batch = _firestore.batch();
      for (final memberDoc in membersSnapshot.docs) {
        batch.delete(memberDoc.reference);
      }
      await batch.commit();

      // ลบกลุ่ม
      await _firestore.collection('community_groups').doc(groupId).delete();

      return true;
    } catch (e) {
      print('Error deleting group: $e');
      return false;
    }
  }

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

      // ลบคอมเมนต์ทั้งหมด
      final commentsSnapshot = await _firestore
          .collection('post_comments')
          .where('postId', isEqualTo: postId)
          .get();

      final batch = _firestore.batch();
      for (final commentDoc in commentsSnapshot.docs) {
        batch.delete(commentDoc.reference);
      }
      await batch.commit();

      // ลบโพสต์
      await _firestore.collection('community_posts').doc(postId).delete();
      print('Post $postId deleted successfully');

      // อัปเดตจำนวนโพสต์ในกลุ่ม
      await updateGroupPostCount(groupId, -1);

      return true;
    } catch (e) {
      print('Error deleting post: $e');
      return false;
    }
  }

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

  // ==================== COMMENT METHODS ====================

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

  // ==================== HELPER METHODS ====================

  Future<void> updateGroupPostCount(String groupId, int change) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final groupRef = _firestore.collection('community_groups').doc(groupId);
        final groupSnapshot = await transaction.get(groupRef);

        if (!groupSnapshot.exists) return;

        final groupData = groupSnapshot.data()!;
        final currentCount = groupData['postCount'] ?? 0;
        final newCount = (currentCount + change).clamp(0, double.infinity).toInt();

        transaction.update(groupRef, {
          'postCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      print('Error updating group post count: $e');
    }
  }

  Future<void> _addGroupMember(String groupId, String userId, String role) async {
    try {
      final memberData = {
        'userId': userId,
        'userEmail': currentUserEmail ?? '',
        'userName': currentUserName ?? '',
        'userAvatar': _auth.currentUser?.photoURL,
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