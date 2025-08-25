import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/community_widgets/community_widgets.dart';

class GroupDetailPage extends StatefulWidget {
  final CommunityGroup group;

  const GroupDetailPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupDetailPageState createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final ScrollController _scrollController = ScrollController();

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
            backgroundColor: const Color(0xFFD2B48C),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.group.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.group.coverImage != null
                      ? Image.network(
                          widget.group.coverImage!,
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
              Container(
                margin: EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'members':
                        _showMembersList();
                        break;
                      case 'settings':
                        _showGroupSettings();
                        break;
                      case 'report':
                        _reportGroup();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'members',
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text('สมาชิก'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text('ตั้งค่า'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.flag, color: Colors.red),
                          SizedBox(width: 8),
                          Text('รายงาน', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Group Info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
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
                  SizedBox(height: 16),
                  
                  // Stats row
                  Row(
                    children: [
                      _buildStatItem(
                        icon: Icons.people,
                        count: widget.group.memberCount,
                        label: 'สมาชิก',
                        onTap: _showMembersList,
                      ),
                      SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.article,
                        count: widget.group.postCount,
                        label: 'โพสต์',
                      ),
                      SizedBox(width: 24),
                      _buildStatItem(
                        icon: Icons.calendar_today,
                        count: DateTime.now().difference(widget.group.createdAt).inDays,
                        label: 'วัน',
                      ),
                    ],
                  ),
                  
                  if (widget.group.tags.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.group.tags.map((tag) => Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2B48C).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFD2B48C).withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            color: const Color(0xFF8B4513),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Divider
          SliverToBoxAdapter(
            child: Container(
              height: 8,
              color: const Color(0xFFF3F6F8),
            ),
          ),
          
          // Posts header
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.article, color: const Color(0xFF8B4513)),
                  SizedBox(width: 8),
                  Text(
                    'โพสต์ในกลุ่ม',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8B4513),
                    ),
                  ),
                  Spacer(),
                  Consumer<CommunityProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoadingPosts) {
                        return SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: const Color(0xFFD2B48C),
                          ),
                        );
                      }
                      return IconButton(
                        icon: Icon(Icons.refresh, color: const Color(0xFF8B4513)),
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
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: const Color(0xFFD2B48C),
                          ),
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
          SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostDialog(),
        backgroundColor: const Color(0xFFD2B48C),
        foregroundColor: Colors.black,
        icon: Icon(Icons.add),
        label: Text(
          'สร้างโพสต์',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFD2B48C), const Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 80,
          color: Colors.white.withOpacity(0.8),
        ),
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
              SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: const Color(0xFF8B4513),
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
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
            Icon(
              Icons.article_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 20),
            Text(
              'ยังไม่มีโพสต์ในกลุ่มนี้',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'เป็นคนแรกที่แชร์เรื่องราวในกลุ่ม!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreatePostDialog(),
              icon: Icon(Icons.add, color: Colors.black),
              label: Text(
                'สร้างโพสต์แรก',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD2B48C),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Fixed: Added the required groupName parameter
      builder: (context) => GroupMembersSheet(
        groupId: widget.group.id,
        groupName: widget.group.name,
      ),
    );
  }

  void _showGroupSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ฟีเจอร์การตั้งค่ากลุ่มกำลังพัฒนา'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _reportGroup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.flag, color: Colors.red),
            SizedBox(width: 8),
            Text('รายงานกลุ่ม'),
          ],
        ),
        content: Text('คุณต้องการรายงานกลุ่มนี้หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ส่งรายงานเรียบร้อยแล้ว'),
                  backgroundColor: Colors.orange[600],
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('รายงาน'),
          ),
        ],
      ),
    );
  }
}