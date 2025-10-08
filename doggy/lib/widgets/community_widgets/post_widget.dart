// widgets/community_widgets/post_widget.dart
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/community_models.dart';
import '../../providers/community_provider.dart';
import 'comments_sheet.dart';

// โทนสีหลักให้สอดคล้องทั้งแอป
const _tan = Color(0xFFD2B48C);
const _brown = Color(0xFF8B4513);

class PostWidget extends StatelessWidget {
  final CommunityPost post;

  const PostWidget({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CommunityProvider>();
    final currentUserId = provider.communityService.currentUserId;
    final isOwner = currentUserId != null && currentUserId == post.authorId;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --------- Header: Author + Menu ---------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _AuthorAvatar(url: post.authorAvatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _brown,
                          )),
                      const SizedBox(height: 2),
                      Text(_formatDate(post.createdAt),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),

                // เมนู: เฉพาะเจ้าของเห็น "แก้ไข/ลบ"
                if (isOwner)
                  PopupMenuButton<_PostMenu>(
                    onSelected: (v) {
                      switch (v) {
                        case _PostMenu.edit:
                          _openEditPost(context, post);
                          break;
                        case _PostMenu.delete:
                          _deletePost(context, post);
                          break;
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _PostMenu.edit,
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('แก้ไขโพสต์'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: _PostMenu.delete,
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red, size: 18),
                            SizedBox(width: 8),
                            Text('ลบโพสต์', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                  ),
              ],
            ),
          ),

          // --------- Content (text) ---------
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                post.content,
                style: TextStyle(fontSize: 16, height: 1.4, color: Colors.grey[800]),
              ),
            ),

          // --------- Images ---------
          if (post.hasImages) ...[
            const SizedBox(height: 12),
            _ImageSection(post: post),
          ],

          // --------- Video ---------
          if (post.hasVideo) ...[
            const SizedBox(height: 12),
            _VideoSection(video: post.video!),
          ],

          // --------- Actions: like / comment / share ---------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Consumer<CommunityProvider>(
                  builder: (context, provider, child) {
                    final liked = post.likedBy.contains(provider.communityService.currentUserId);
                    return InkWell(
                      onTap: () => provider.togglePostLike(post.id),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : Colors.grey[600], size: 22),
                            const SizedBox(width: 6),
                            Text('${post.likeCount}',
                                style: TextStyle(
                                  color: liked ? Colors.red : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _showComments(context, post),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.comment_outlined, color: Colors.grey[600], size: 22),
                        const SizedBox(width: 6),
                        Text('${post.commentCount}',
                            style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                InkWell(
                  onTap: () => _share(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Icon(Icons.share_outlined, color: Colors.grey[600], size: 22),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== helpers =====

  void _openEditPost(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditPostSheet(post: post),
    );
  }

  void _deletePost(BuildContext context, CommunityPost post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(children: [
          const Icon(Icons.delete, color: Colors.red),
          const SizedBox(width: 8),
          const Text('ลบโพสต์'),
        ]),
        content: const Text(
          'คุณต้องการลบโพสต์นี้หรือไม่?\nการดำเนินการนี้ไม่สามารถยกเลิกได้',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(child: CircularProgressIndicator(color: _tan)),
              );
              final provider = context.read<CommunityProvider>();
              final ok = await provider.deletePost(post.id, post.groupId);
              Navigator.pop(context); // close loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [
                    Icon(ok ? Icons.check_circle : Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(ok ? 'ลบโพสต์เรียบร้อยแล้ว' : (provider.error ?? 'ไม่สามารถลบโพสต์ได้')),
                  ]),
                  backgroundColor: ok ? Colors.green[600] : Colors.red[600],
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
  }

  void _showComments(BuildContext context, CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsSheet(post: post),
    );
  }

  void _share(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: const [
          Icon(Icons.share, color: Colors.white),
          SizedBox(width: 8),
          Text('ฟีเจอร์แชร์กำลังพัฒนา'),
        ]),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

enum _PostMenu { edit, delete }

// ==================== Sub-widgets ====================

class _AuthorAvatar extends StatelessWidget {
  final String? url;
  const _AuthorAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return const CircleAvatar(radius: 22, backgroundColor: _tan, child: Icon(Icons.person, color: Colors.white, size: 26));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: _tan,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: CachedNetworkImage(
          imageUrl: url!,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => const _AvatarPlaceholder(),
          errorWidget: (_, __, ___) => const _AvatarPlaceholder(),
        ),
      ),
    );
  }
}

class _AvatarPlaceholder extends StatelessWidget {
  const _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(color: _tan, child: const Icon(Icons.person, color: Colors.white, size: 26));
  }
}

class _ImageSection extends StatelessWidget {
  final CommunityPost post;
  const _ImageSection({required this.post});

  @override
  Widget build(BuildContext context) {
    if (post.images.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 250,
      child: post.images.length == 1
          ? _SingleImage(image: post.images.first)
          : _ImageCarousel(images: post.images),
    );
  }
}

class _SingleImage extends StatelessWidget {
  final PostImage image;
  const _SingleImage({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => _openImageViewer(context, [image], 0),
          child: Hero(
            tag: 'image_${image.publicId}',
            child: CachedNetworkImage(
              imageUrl: image.mediumUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              placeholder: (_, __) => _imageLoading(),
              errorWidget: (_, __, ___) => _imageError(),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageCarousel extends StatelessWidget {
  final List<PostImage> images;
  const _ImageCarousel({required this.images});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (_, i) {
        final img = images[i];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _openImageViewer(context, images, i),
              child: Hero(
                tag: 'image_${img.publicId}',
                child: Stack(
                  children: [
                    CachedNetworkImage(
                      imageUrl: img.mediumUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _imageLoading(),
                      errorWidget: (_, __, ___) => _imageError(),
                    ),
                    if (images.length > 1)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text('${i + 1}/${images.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

Widget _imageLoading() => Container(
      color: Colors.grey[300],
      child: const Center(child: CircularProgressIndicator(color: _tan)),
    );

Widget _imageError() => Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 50, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );

void _openImageViewer(BuildContext context, List<PostImage> images, int initialIndex) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ImageViewerPage(images: images, initialIndex: initialIndex)),
  );
}

class _VideoSection extends StatelessWidget {
  final PostVideo video;
  const _VideoSection({required this.video});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video))),
        borderRadius: BorderRadius.circular(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (video.thumbnailUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (_, __) => _videoPlaceholder(),
                  errorWidget: (_, __, ___) => _videoPlaceholder(),
                )
              else
                _videoPlaceholder(),
              Container(color: Colors.black.withOpacity(0.3)),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
                    child: const Icon(Icons.play_arrow, size: 40, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(video.formattedDuration, style: const TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: Colors.white, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(video.formattedSize, style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)),
                  child: Text('${video.width}x${video.height}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _videoPlaceholder() => Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[800]!, Colors.grey[900]!]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.videocam, size: 60, color: Colors.white.withOpacity(0.7)),
    );

// ==================== Edit Post Sheet ====================

class EditPostSheet extends StatefulWidget {
  final CommunityPost post;
  const EditPostSheet({Key? key, required this.post}) : super(key: key);

  @override
  State<EditPostSheet> createState() => _EditPostSheetState();
}

class _EditPostSheetState extends State<EditPostSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _contentCtl;

  final ImagePicker _picker = ImagePicker();

  // รูปเดิมที่ต้องการลบ (เก็บ publicId)
  final Set<String> _imagesToDelete = {};

  // รูปใหม่ที่เพิ่ม (XFile)
  final List<XFile> _newImages = [];

  // วิดีโอใหม่ / ลบวิดีโอเดิม
  XFile? _newVideo;
  bool _removeVideo = false;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _contentCtl = TextEditingController(text: widget.post.content);
  }

  @override
  void dispose() {
    _contentCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommunityProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(999))),
              const SizedBox(height: 8),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: _brown),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('แก้ไขโพสต์', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _brown)),
                    ),
                    TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('ยกเลิก')),
                    const SizedBox(width: 4),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _submit,
                      icon: _saving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: const Text('บันทึก'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _tan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Content
                        TextFormField(
                          controller: _contentCtl,
                          maxLines: null,
                          minLines: 3,
                          decoration: _decoration('ข้อความโพสต์'),
                          validator: (v) => context.read<CommunityProvider>().validatePostContent(v ?? ''),
                        ),
                        const SizedBox(height: 16),

                        // Images (old + new)
                        _buildImagesSection(),

                        const SizedBox(height: 16),

                        // Video
                        _buildVideoSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Images ----------
  Widget _buildImagesSection() {
    final existing = widget.post.images;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('รูปภาพ', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        if (existing.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: existing.map((img) {
              final marked = _imagesToDelete.contains(img.publicId);
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.mode(
                        marked ? Colors.black.withOpacity(0.45) : Colors.transparent,
                        BlendMode.darken,
                      ),
                      child: CachedNetworkImage(
                        imageUrl: img.thumbnailUrl.isNotEmpty ? img.thumbnailUrl : img.mediumUrl,
                        width: 96, height: 96, fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          if (marked) {
                            _imagesToDelete.remove(img.publicId);
                          } else {
                            _imagesToDelete.add(img.publicId);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: marked ? Colors.red : Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(marked ? Icons.restore_from_trash : Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (_imagesToDelete.isNotEmpty)
            Text('จะลบรูป ${_imagesToDelete.length} รูป เมื่อบันทึก',
                style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
        ],

        if (_newImages.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _newImages.map((x) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(File(x.path), width: 96, height: 96, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4, right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _newImages.remove(x)),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: _pickNewImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('เพิ่มรูป'),
            ),
            const SizedBox(width: 8),
            if (_newImages.isNotEmpty)
              Text('${_newImages.length} รูปใหม่ถูกเลือก',
                  style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Future<void> _pickNewImages() async {
    try {
      final files = await _picker.pickMultiImage(imageQuality: 90, maxWidth: 2000, maxHeight: 2000);
      if (files.isEmpty) return;

      // Validation จาก provider (ขนาด/จำนวน)
      final msg = await context.read<CommunityProvider>().validateImages(files);
      if (msg != null) {
        _snack(msg);
        return;
      }

      setState(() => _newImages.addAll(files));
    } catch (e) {
      _snack('ไม่สามารถเลือกรูปได้: $e');
    }
  }

  // ---------- Video ----------
  Widget _buildVideoSection() {
    final hasOld = widget.post.video != null && !_removeVideo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('วิดีโอ', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),

        if (hasOld)
          Container(
            height: 140,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.post.video!.thumbnailUrl.isNotEmpty)
                  CachedNetworkImage(imageUrl: widget.post.video!.thumbnailUrl, fit: BoxFit.cover)
                else
                  _videoPlaceholder(),
                Container(color: Colors.black26),
                const Center(
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 36),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _removeVideo = true),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.red[700], shape: BoxShape.circle),
                      child: const Icon(Icons.delete, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

        if (!hasOld && _newVideo != null)
          Container(
            height: 140,
            decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(8)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const Center(child: Icon(Icons.videocam, color: Colors.white70, size: 40)),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _newVideo = null),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: hasOld ? null : _pickNewVideo,
              icon: const Icon(Icons.video_call),
              label: const Text('เพิ่ม/แทนที่วิดีโอ'),
            ),
            const SizedBox(width: 8),
            if (_removeVideo) const Text('จะลบวิดีโอเดิม', style: TextStyle(color: Colors.red)),
            if (_newVideo != null) const Text('เลือกวิดีโอใหม่แล้ว'),
          ],
        ),
      ],
    );
  }

  Future<void> _pickNewVideo() async {
    try {
      final v = await _picker.pickVideo(source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
      if (v == null) return;

      final msg = await context.read<CommunityProvider>().validateVideo(v);
      if (msg != null) {
        _snack(msg);
        return;
      }

      setState(() {
        _newVideo = v;
        _removeVideo = false; // มีวิดีโอใหม่แล้ว ไม่ถือว่าลบ
      });
    } catch (e) {
      _snack('ไม่สามารถเลือดวิดีโอได้: $e');
    }
  }

  // ---------- Submit ----------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final provider = context.read<CommunityProvider>();

      final ok = await provider.updatePost(
        postId: widget.post.id,
        newContent: _contentCtl.text.trim(),
        newImageFiles: _newImages.isEmpty ? null : _newImages,
        imagesToDelete: _imagesToDelete.isEmpty ? null : _imagesToDelete.toList(),
        newVideoFile: _newVideo,
        removeVideo: _removeVideo,
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('อัปเดตโพสต์เรียบร้อยแล้ว'),
            ]),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _snack(provider.error ?? 'ไม่สามารถแก้ไขโพสต์ได้');
      }
    } catch (e) {
      _snack('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ---------- Utils ----------
  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _tan, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ==================== Image Viewer Page ====================

class ImageViewerPage extends StatefulWidget {
  final List<PostImage> images;
  final int initialIndex;

  const ImageViewerPage({Key? key, required this.images, required this.initialIndex}) : super(key: key);

  @override
  _ImageViewerPageState createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.images.length;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / $total', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: total,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (_, i) {
          final img = widget.images[i];
          return Center(
            child: Hero(
              tag: 'image_${img.publicId}',
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: img.url, // full res
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: _tan)),
                  errorWidget: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 64),
                        SizedBox(height: 16),
                        Text('ไม่สามารถโหลดรูปภาพได้', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== Video Player Page ====================

class VideoPlayerPage extends StatefulWidget {
  final PostVideo video;
  const VideoPlayerPage({Key? key, required this.video}) : super(key: key);

  @override
  _VideoPlayerPageState createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VideoPlayerController _controller;
  bool _ready = false;
  bool _err = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      _controller = VideoPlayerController.network(widget.video.url);
      await _controller.initialize();
      setState(() => _ready = true);
      _controller.play();
    } catch (e) {
      setState(() => _err = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar:
          AppBar(backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white), title: const Text('วิดีโอ', style: TextStyle(color: Colors.white))),
      body: Center(
        child: _err
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  const Text('ไม่สามารถเล่นวิดีโอได้', style: TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต', style: TextStyle(color: Colors.grey[400])),
                ],
              )
            : !_ready
                ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: _tan),
                      SizedBox(height: 16),
                      Text('กำลังโหลดวิดีโอ...', style: TextStyle(color: Colors.white)),
                    ],
                  )
                : AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller)),
      ),
      floatingActionButton: _ready && !_err
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying ? _controller.pause() : _controller.play();
                });
              },
              backgroundColor: _tan,
              child: Icon(_controller.value.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.black),
            )
          : null,
    );
  }
}

// ==================== Misc ====================

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final d = now.difference(date);
  if (d.inMinutes < 60) return '${d.inMinutes} นาทีที่แล้ว';
  if (d.inHours < 24) return '${d.inHours} ชั่วโมงที่แล้ว';
  if (d.inDays < 7) return '${d.inDays} วันที่แล้ว';
  return '${date.day}/${date.month}/${date.year}';
}
