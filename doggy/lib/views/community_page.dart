import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../models/community_models.dart';
import '../widgets/bottom_navbar.dart';
import 'group_detail_page.dart';
import '../widgets/community_widgets/community_widgets.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // โทนสีหลักของแอป
  static const Color _tan = Color(0xFFD2B48C);
  static const Color _brown = Color(0xFF8B4513);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // เริ่มโหลดข้อมูลแบบ realtime
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

  // ===================== Scaffold =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F8),
      appBar: AppBar(
        title: const Text(
          'ชุมชน',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: _tan,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _tan,
                _tan.withOpacity(0.9),
              ],
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: _brown,
              unselectedLabelColor: Colors.black54,
              indicatorColor: _brown,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              tabs: const [
                Tab(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('กลุ่มของฉัน'))),
                Tab(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('ค้นพบกลุ่ม'))),
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.black, size: 28),
              onPressed: _showCreateGroupDialog,
              tooltip: 'สร้างกลุ่มใหม่',
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.black, size: 26),
              onPressed: _showSearchDialog,
              tooltip: 'ค้นหากลุ่ม',
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUserGroupsTab(),
          _buildAllGroupsTab(),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  // ===================== Tabs =====================

  Widget _buildUserGroupsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.userGroups.isEmpty) {
          return _LoadingState(text: 'กำลังโหลดกลุ่มของคุณ...');
        }

        if (provider.userGroups.isEmpty && !provider.isLoading) {
          return _buildEmptyUserGroups();
        }

        return RefreshIndicator(
          onRefresh: () async => provider.refreshAll(),
          color: _tan,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.userGroups.length,
            itemBuilder: (_, i) {
              final group = provider.userGroups[i];
              return _buildGroupCard(group, isJoined: true);
            },
          ),
        );
      },
    );
  }

  Widget _buildAllGroupsTab() {
    return Consumer<CommunityProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.allGroups.isEmpty) {
          return _LoadingState(text: 'กำลังโหลดกลุ่มทั้งหมด...');
        }

        if (provider.allGroups.isEmpty && !provider.isLoading) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_outlined,
                      size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('ยังไม่มีกลุ่มในระบบ',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('เป็นคนแรกที่สร้างกลุ่ม!',
                      style: TextStyle(color: Colors.grey[500])),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => provider.refreshAll(),
          color: _tan,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.allGroups.length,
            itemBuilder: (_, i) {
              final group = provider.allGroups[i];
              final isJoined = provider.userGroups.any((g) => g.id == group.id);
              return _buildGroupCard(group, isJoined: isJoined);
            },
          ),
        );
      },
    );
  }

  // ===================== Group Card =====================

  Widget _buildGroupCard(CommunityGroup group, {required bool isJoined}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _tan.withOpacity(0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openGroup(group),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: (group.coverImage != null &&
                            group.coverImage!.isNotEmpty)
                        ? Image.network(
                            group.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildDefaultCover(),
                          )
                        : _buildDefaultCover(),
                  ),
                  // Gradient ด้านล่าง
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.center,
                            colors: [
                              Colors.black.withOpacity(0.55),
                              Colors.transparent
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // ชื่อกลุ่ม + สมาชิก + badge
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 10,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _InitialAvatar(
                            text: group.name, size: 36, bg: _tan, fg: _brown),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.people,
                                      size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${group.memberCount} สมาชิก',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isJoined)
                          _GlassBadge(
                            text: 'เข้าร่วมแล้ว',
                            icon: Icons.check_circle,
                            bg: Colors.green.withOpacity(0.9),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // เนื้อหา
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (group.description.trim().isNotEmpty) ...[
                    Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (group.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: group.tags.take(3).map((t) {
                        return _TagChip(text: '#$t', tan: _tan, brown: _brown);
                      }).toList(),
                    ),
                  if (group.tags.isNotEmpty) const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatChip(
                          icon: Icons.article,
                          label: '${group.postCount} โพสต์'),
                      const SizedBox(width: 10),
                      _StatChip(
                          icon: Icons.people_alt,
                          label: '${group.memberCount} คน'),
                      const Spacer(),
                      _JoinLeaveButton(
                        isJoined: isJoined,
                        onJoin: () => _joinGroup(group.id),
                        onLeave: () => _leaveGroup(group.id),
                        tan: _tan,
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

  // ===================== Fallback / Empty =====================

  Widget _buildDefaultCover() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_tan, _brown],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(Icons.pets, size: 48, color: Colors.white.withOpacity(0.85)),
    );
  }

  Widget _buildEmptyUserGroups() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _tan.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.groups_outlined, size: 80, color: _brown),
            ),
            const SizedBox(height: 32),
            const Text(
              'ยังไม่ได้เข้าร่วมกลุ่มใดเลย',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: _brown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'ค้นหาและเข้าร่วมกลุ่มที่คุณสนใจ\nหรือสร้างกลุ่มใหม่ของคุณเอง',
              style:
                  TextStyle(fontSize: 16, color: Colors.grey[600], height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _tabController.animateTo(1),
                  icon: const Icon(Icons.search, color: Colors.black),
                  label: const Text('ค้นหากลุ่ม',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _tan,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 3,
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: _showCreateGroupDialog,
                  icon: const Icon(Icons.add, color: _brown),
                  label: const Text('สร้างกลุ่ม',
                      style: TextStyle(
                          color: _brown, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _tan, width: 2),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===================== Actions =====================

  void _openGroup(CommunityGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GroupDetailPage(group: group)),
    );
  }

  Future<void> _joinGroup(String groupId) async {
    final provider = context.read<CommunityProvider>();
    final success = await provider.joinGroup(groupId);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('เข้าร่วมกลุ่มเรียบร้อยแล้ว'),
          ]),
          backgroundColor: Colors.green[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(provider.error ?? 'ไม่สามารถเข้าร่วมกลุ่มได้'),
          ]),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _leaveGroup(String groupId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('ออกจากกลุ่ม'),
          ],
        ),
        content: const Text(
          'คุณต้องการออกจากกลุ่มนี้หรือไม่?\nคุณสามารถเข้าร่วมใหม่ได้ภายหลัง',
          style: TextStyle(height: 1.4),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
            ),
            child: const Text('ออกจากกลุ่ม'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final provider = context.read<CommunityProvider>();
      final success = await provider.leaveGroup(groupId);
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: const [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('ออกจากกลุ่มเรียบร้อยแล้ว'),
            ]),
            backgroundColor: Colors.orange[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text(provider.error ?? 'ไม่สามารถออกจากกลุ่มได้'),
            ]),
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
    showDialog(context: context, builder: (_) => CreateGroupDialog());
  }

  void _showSearchDialog() {
    showDialog(context: context, builder: (_) => SearchGroupDialog());
  }
}

// ===================== Small Reusable Widgets =====================

class _LoadingState extends StatelessWidget {
  final String text;
  const _LoadingState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: const Color(0xFFD2B48C)),
        const SizedBox(height: 16),
        Text(text),
      ]),
    );
  }
}

class _InitialAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color bg;
  final Color fg;
  const _InitialAvatar({
    required this.text,
    this.size = 40,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    final String initial =
        text.trim().isEmpty ? 'G' : text.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.5,
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color bg;
  const _GlassBadge({required this.text, required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Color(0xFFF3F6F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color tan;
  final Color brown;
  const _TagChip({required this.text, required this.tan, required this.brown});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tan.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tan.withOpacity(0.55)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: brown,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _JoinLeaveButton extends StatefulWidget {
  final bool isJoined;
  final Future<void> Function() onJoin;
  final Future<void> Function() onLeave;
  final Color tan;

  const _JoinLeaveButton({
    required this.isJoined,
    required this.onJoin,
    required this.onLeave,
    required this.tan,
  });

  @override
  State<_JoinLeaveButton> createState() => _JoinLeaveButtonState();
}

class _JoinLeaveButtonState extends State<_JoinLeaveButton> {
  bool _busy = false;

  Future<void> _handle() async {
    setState(() => _busy = true);
    try {
      if (widget.isJoined) {
        await widget.onLeave();
      } else {
        await widget.onJoin();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool joined = widget.isJoined;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: SizedBox(
        key: ValueKey(joined),
        height: 36,
        child: ElevatedButton(
          onPressed: _busy ? null : _handle,
          style: ElevatedButton.styleFrom(
            backgroundColor: joined ? Colors.grey[200] : widget.tan,
            foregroundColor: Colors.black,
            elevation: joined ? 0 : 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  joined ? 'ออก' : 'เข้าร่วม',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
        ),
      ),
    );
  }
}
