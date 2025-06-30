// widgets/community_widgets/group_members_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';

class GroupMembersSheet extends StatelessWidget {
  final String groupId;

  const GroupMembersSheet({Key? key, required this.groupId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: EdgeInsets.only(top: 12, bottom: 16),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.people, color: const Color(0xFF8B4513), size: 24),
                    SizedBox(width: 8),
                    Text(
                      'สมาชิกในกลุ่ม',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B4513),
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 32),
              
              // Members list
              Expanded(
                child: StreamBuilder<List<GroupMember>>(
                  stream: context.read<CommunityProvider>().getGroupMembers(groupId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFD2B48C),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: 16),
                            Text(
                              'ไม่พบสมาชิก',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final members = snapshot.data!;
                    return ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        return _buildMemberItem(member);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMemberItem(GroupMember member) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundImage: member.userAvatar != null
              ? NetworkImage(member.userAvatar!)
              : null,
          backgroundColor: const Color(0xFFD2B48C),
          child: member.userAvatar == null
              ? Icon(Icons.person, color: Colors.white, size: 24)
              : null,
        ),
        title: Text(
          member.userName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              member.userEmail,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'เข้าร่วมเมื่อ ${_formatDate(member.joinedAt)}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: member.role == 'admin'
            ? Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'แอดมิน',
                  style: TextStyle(
                    color: Colors.orange[800],
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}