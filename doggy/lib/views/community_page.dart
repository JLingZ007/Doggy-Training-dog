import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/bottom_navbar.dart';
import 'group_detail_page.dart';
import '../widgets/community_widgets/community_widgets.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 3; // Index สำหรับ Community ใน Bottom Nav

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // เริ่ม real-time streams
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CommunityProvider>();
      provider.loadAllGroups();
      provider.loadUserGroups();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: Text(
          'ชุมชน',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFD2B48C),
                const Color(0xFFD2B48C).withOpacity(0.9),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, -1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF8B4513),
              unselectedLabelColor: Colors.black54,
              indicatorColor: const Color(0xFF8B4513),
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              tabs: [
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('กลุ่มของฉัน'),
                  ),
                ),
                Tab(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text('ค้นพบกลุ่ม'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.add_circle, color: Colors.black, size: 28),
              onPressed: () => _showCreateGroupDialog(),
              tooltip: 'สร้างกลุ่มใหม่',
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: Icon(Icons.search, color: Colors.black, size: 26),
              onPressed: () => _showSearchDialog(),
              tooltip: 'ค้นหากลุ่ม',
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserGroupsTab(),
          _buildAllGroupsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // หน้าหลัก
      ),
    );
  }

  Widget _buildUserGroupsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        // แสดง loading เฉพาะเมื่อไม่มีข้อมูล
        if (provider.isLoading && provider.userGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFFD2B48C),
                ),
                SizedBox(height: 16),
                Text('กำลังโหลดกลุ่มของคุณ...'),
              ],
            ),
          );
        }

        if (provider.userGroups.isEmpty && !provider.isLoading) {
          return _buildEmptyUserGroups();
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.refreshAll();
          },
          color: const Color(0xFFD2B48C),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.userGroups.length,
            itemBuilder: (context, index) {
              final group = provider.userGroups[index];
              return _buildGroupCard(group, isJoined: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGroupsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, child) {
        // แสดง loading เฉพาะเมื่อไม่มีข้อมูล
        if (provider.isLoading && provider.allGroups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color(0xFFD2B48C),
                ),
                SizedBox(height: 16),
                Text('กำลังโหลดกลุ่มทั้งหมด...'),
              ],
            ),
          );
        }

        if (provider.allGroups.isEmpty && !provider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.groups_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'ยังไม่มีกลุ่มในระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'เป็นคนแรกที่สร้างกลุ่ม!',
                  style: TextStyle(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.refreshAll();
          },
          color: const Color(0xFFD2B48C),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: provider.allGroups.length,
            itemBuilder: (context, index) {
              final group = provider.allGroups[index];
              final isJoined = provider.userGroups.any((g) => g.id == group.id);
              return _buildGroupCard(group, isJoined: isJoined);
            },
          ),
        );
      },
    );
  }

  Widget _buildGroupCard(CommunityGroup group, {required bool isJoined}) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _openGroup(group),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [const Color(0xFFD2B48C), const Color(0xFF8B4513)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  if (group.coverImage != null)
                    ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        group.coverImage!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 140,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildDefaultCover(),
                      ),
                    )
                  else
                    _buildDefaultCover(),

                  // Status badge
                  if (isJoined)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'เข้าร่วมแล้ว',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name and member count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8B4513),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD2B48C).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people,
                                size: 14, color: const Color(0xFF8B4513)),
                            SizedBox(width: 4),
                            Text(
                              '${group.memberCount}',
                              style: TextStyle(
                                color: const Color(0xFF8B4513),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),
                  Text(
                    group.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 12),

                  // Tags
                  if (group.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: group.tags
                          .take(3)
                          .map((tag) => Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFD2B48C).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFD2B48C)
                                        .withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    color: const Color(0xFF8B4513),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),

                  SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      Icon(Icons.article, size: 16, color: Colors.grey[500]),
                      SizedBox(width: 4),
                      Text(
                        '${group.postCount} โพสต์',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Spacer(),
                      Consumer<CommunityProvider>(
                        builder: (context, provider, child) {
                          return ElevatedButton(
                            onPressed: provider.isLoading
                                ? null
                                : () => isJoined
                                    ? _leaveGroup(group.id)
                                    : _joinGroup(group.id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isJoined
                                  ? Colors.grey[300]
                                  : const Color(0xFFD2B48C),
                              foregroundColor:
                                  isJoined ? Colors.grey[700] : Colors.black,
                              minimumSize: Size(90, 36),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: isJoined ? 1 : 2,
                            ),
                            child: provider.isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: isJoined
                                          ? Colors.grey[700]
                                          : Colors.black,
                                    ),
                                  )
                                : Text(
                                    isJoined ? 'ออก' : 'เข้าร่วม',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultCover() {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        gradient: LinearGradient(
          colors: [const Color(0xFFD2B48C), const Color(0xFF8B4513)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.pets,
          size: 48,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildEmptyUserGroups() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD2B48C).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_outlined,
                size: 80,
                color: const Color(0xFF8B4513),
              ),
            ),
            SizedBox(height: 32),
            Text(
              'ยังไม่ได้เข้าร่วมกลุ่มใดเลย',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF8B4513),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'ค้นหาและเข้าร่วมกลุ่มที่คุณสนใจ\nหรือสร้างกลุ่มใหม่ของคุณเอง',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: Icon(Icons.search, color: Colors.black),
                  label: Text(
                    'ค้นหากลุ่ม',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD2B48C),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 3,
                  ),
                ),
                SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => _showCreateGroupDialog(),
                  icon: Icon(Icons.add, color: const Color(0xFF8B4513)),
                  label: Text(
                    'สร้างกลุ่ม',
                    style: TextStyle(
                      color: const Color(0xFF8B4513),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: const Color(0xFFD2B48C), width: 2),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openGroup(CommunityGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailPage(group: group),
      ),
    );
  }

  void _joinGroup(String groupId) async {
    final provider = context.read<CommunityProvider>();
    final success = await provider.joinGroup(groupId);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('เข้าร่วมกลุ่มเรียบร้อยแล้ว'),
            ],
          ),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text(provider.error ?? 'ไม่สามารถเข้าร่วมกลุ่มได้'),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _leaveGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            SizedBox(width: 8),
            Text('ออกจากกลุ่ม'),
          ],
        ),
        content: Text(
          'คุณต้องการออกจากกลุ่มนี้หรือไม่?\nคุณสามารถเข้าร่วมใหม่ได้ภายหลัง',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: Text('ออกจากกลุ่ม'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<CommunityProvider>();
      final success = await provider.leaveGroup(groupId);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info, color: Colors.white),
                SizedBox(width: 8),
                Text('ออกจากกลุ่มเรียบร้อยแล้ว'),
              ],
            ),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8),
                Text(provider.error ?? 'ไม่สามารถออกจากกลุ่มได้'),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showCreateGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateGroupDialog(),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => SearchGroupDialog(),
    );
  }
}
