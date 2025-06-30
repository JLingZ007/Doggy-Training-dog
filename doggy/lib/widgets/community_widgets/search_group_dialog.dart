// widgets/community_widgets/search_group_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../models/community_models.dart';
import '../../views/group_detail_page.dart';

class SearchGroupDialog extends StatefulWidget {
  @override
  _SearchGroupDialogState createState() => _SearchGroupDialogState();
}

class _SearchGroupDialogState extends State<SearchGroupDialog> {
  final _searchController = TextEditingController();
  List<CommunityGroup> _searchResults = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.search, color: const Color(0xFF8B4513), size: 28),
                SizedBox(width: 12),
                Text(
                  'ค้นหากลุ่ม',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'ค้นหาชื่อกลุ่ม, คำอธิบาย, หรือแท็ก...',
                prefixIcon: Icon(Icons.search, color: const Color(0xFF8B4513)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: const Color(0xFFD2B48C), width: 2),
                ),
              ),
              onSubmitted: _searchGroups,
              onChanged: (value) {
                if (value.isEmpty) {
                  setState(() {
                    _searchResults = [];
                  });
                }
              },
            ),
            
            SizedBox(height: 20),
            
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: const Color(0xFFD2B48C)),
                          SizedBox(height: 16),
                          Text('กำลังค้นหา...'),
                        ],
                      ),
                    )
                  : _searchResults.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'ค้นหากลุ่มที่คุณสนใจ'
                                    : 'ไม่พบกลุ่มที่ตรงกับการค้นหา',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final group = _searchResults[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: const Color(0xFFD2B48C),
                                  child: Icon(Icons.pets, color: Colors.white),
                                ),
                                title: Text(
                                  group.name,
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      group.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${group.memberCount} สมาชิก',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.arrow_forward_ios, size: 16),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GroupDetailPage(group: group),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _searchGroups(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final provider = context.read<CommunityProvider>();
    final results = await provider.searchGroups(query.trim());

    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }
}