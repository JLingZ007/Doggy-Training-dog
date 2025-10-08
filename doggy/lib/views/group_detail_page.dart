import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/community_widgets/community_widgets.dart';
import '../widgets/community_widgets/edit_group_dialog.dart';

class GroupDetailPage extends StatefulWidget {
  final CommunityGroup group;

  const GroupDetailPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ScrollController _scrollController = ScrollController();

  static const _tan = Color(0xFFD2B48C);
  static const _brown = Color(0xFF8B4513);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadGroupPosts(widget.group.id);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: _tan,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.group.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  (widget.group.hasCoverImage)
                      ? Image.network(
                          widget.group.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
                        )
                      : _buildDefaultCover(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // เมนู: สมาชิก (ทุกคนเห็น) + แก้ไข/ลบ (เฉพาะเจ้าของ)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Consumer<CommunityProvider>(
                  builder: (context, provider, _) {
                    final currentUserId = provider.communityService.currentUserId;
                    final isOwner = currentUserId != null && widget.group.createdBy == currentUserId;

                    return PopupMenuButton<_MenuAction>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) {
                        switch (value) {
                          case _MenuAction.members:
                            _showMembersList();
                            break;
                          case _MenuAction.edit:
                            _editGroup();
                            break;
                          case _MenuAction.delete:
                            _deleteGroup();
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<_MenuAction>>[
                          PopupMenuItem(
                            value: _MenuAction.members,
                            child: Row(
                              children: [
                                Icon(Icons.people, color: Colors.grey[700]),
                                const SizedBox(width: 8),
                                const Text('สมาชิก'),
                              ],
                            ),
                          ),
                        ];
                        if (isOwner) {
                          items.addAll([
                            const PopupMenuItem(
                              value: _MenuAction.edit,
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text('แก้ไขกลุ่ม'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: _MenuAction.delete,
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('ลบกลุ่ม', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ]);
                        }
                        return items;
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Group Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.group.description,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.people,
                        count: widget.group.memberCount,
                        label: 'สมาชิก',
                        onTap: _showMembersList,
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.article,
                        count: widget.group.postCount,
                        label: 'โพสต์',
                      ),
                      const SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.calendar_today,
                        count: DateTime.now().difference(widget.group.createdAt).inDays,
                        label: 'วัน',
                      ),
                    ],
                  ),

                  if (widget.group.tags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.group.tags
                          .map(
                            (tag) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _tan.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _tan.withOpacity(0.5)),
                              ),
                              child: Text(
                                '#$tag',
                                style: const TextStyle(
                                  color: _brown,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Divider
          SliverToBoxAdapter(
            child: Container(height: 8, color: const Color(0xFFF3F6F8)),
          ),

          // Posts header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.article, color: _brown),
                  const SizedBox(width: 8),
                  const Text(
                    'โพสต์ในกลุ่ม',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _brown),
                  ),
                  const Spacer(),
                  Consumer<CommunityProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingPosts) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _tan),
                        );
                      }
                      return IconButton(
                        icon: const Icon(Icons.refresh, color: _brown),
                        onPressed: () => provider.loadGroupPosts(widget.group.id),
                        tooltip: 'รีเฟรช',
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Posts
          Consumer<CommunityProvider>(
            builder: (context, provider, child) {
              if (provider.isLoadingPosts) {
                return SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    color: Colors.white,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: _tan),
                          SizedBox(height: 16),
                          Text('กำลังโหลดโพสต์...'),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (provider.currentGroupPosts.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyPosts());
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = provider.currentGroupPosts[index];
                    return PostWidget(post: post);
                  },
                  childCount: provider.currentGroupPosts.length,
                ),
              );
            },
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: _tan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('สร้างโพสต์', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_tan, _brown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(Icons.pets, size: 80, color: Colors.white.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildEmptyPosts() {
    return Container(
      height: 300,
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'ยังไม่มีโพสต์ในกลุ่มนี้',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text('เป็นคนแรกที่แชร์เรื่องราวในกลุ่ม!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreatePostDialog,
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text('สร้างโพสต์แรก',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _tan,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreatePostSheet(groupId: widget.group.id),
    );
  }

  void _showMembersList() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => GroupMembersSheet(
        groupId: widget.group.id,
        groupName: widget.group.name,
      ),
    );
  }

  // ====== Owner actions ======
  void _editGroup() {
    showDialog(context: context, builder: (_) => EditGroupDialog(group: widget.group));
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[600]),
            const SizedBox(width: 8),
            const Text('ลบกลุ่ม'),
          ],
        ),
        content: const Text(
          'การลบกลุ่มจะลบเนื้อหา/โพสต์ทั้งหมดภายในกลุ่มนี้\nดำเนินการต่อหรือไม่?',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
            child: const Text('ลบกลุ่ม'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<CommunityProvider>();
      final ok = await provider.deleteGroup(widget.group.id);
      if (!mounted) return;

      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.delete_forever, color: Colors.white), SizedBox(width: 8),
              Text('ลบกลุ่มเรียบร้อยแล้ว'),
            ]),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context); // กลับจากหน้ารายละเอียด เพราะกลุ่มหายแล้ว
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error, color: Colors.white), const SizedBox(width: 8),
              Text(provider.error ?? 'ไม่สามารถลบกลุ่มได้'),
            ]),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}

enum _MenuAction { members, edit, delete }
