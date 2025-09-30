import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/community_provider.dart';
import '../../models/community_models.dart';

class SearchGroupDialog extends StatefulWidget {
  @override
  State<SearchGroupDialog> createState() => _SearchGroupDialogState();
}

class _SearchGroupDialogState extends State<SearchGroupDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  bool _isSearching = false;
  bool _hasSearched = false;
  bool _showSuggestions = false;

  List<CommunityGroup> _results = [];
  List<String> _nameSuggestions = [];

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _showSuggestions = _searchFocus.hasFocus);
      if (_searchFocus.hasFocus && _searchController.text.trim().isNotEmpty) {
        _debouncedFetchNameSuggestions(_searchController.text.trim());
      }
    });
    _searchController.addListener(() {
      if (_searchFocus.hasFocus) {
        _debouncedFetchNameSuggestions(_searchController.text.trim());
      }
      if (!_isSearching && !_hasSearched) setState(() {});
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ===== Suggest เฉพาะ "ชื่อกลุ่ม" =====
  void _debouncedFetchNameSuggestions(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () async {
      if (!mounted) return;
      final query = q.trim();
      if (query.isEmpty) {
        setState(() => _nameSuggestions = []);
        return;
      }
      try {
        final provider = context.read<CommunityProvider>();
        final matches = await provider.searchGroups(query);
        final names = matches.map((g) => g.name).toSet().toList();
        setState(() => _nameSuggestions = names.take(20).toList());
      } catch (_) {}
    });
  }

  Future<void> _performSearch(String text) async {
    final q = text.trim();
    if (q.isEmpty) return;

    // ปิดคีย์บอร์ดเฉพาะตอน "ค้นหา"
    _searchFocus.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _showSuggestions = false;
    });

    try {
      final provider = context.read<CommunityProvider>();
      final data = await provider.searchGroups(q);
      if (!mounted) return;
      setState(() => _results = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('เกิดข้อผิดพลาดในการค้นหา'),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeBrown = const Color(0xFF8B4513);
    final themeTan = const Color(0xFFD2B48C);

    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final topPad = mq.viewPadding.top;

    // ===== ไม่ใช้ viewInsets เลย (ให้คีย์บอร์ดทับได้) =====
    final target = screenH * 0.58; // ลอยกลางจอ กำลังดีบนมือถือ
    final dialogHeight = math.max(360.0, math.min(screenH * 0.8, target));

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        bottom: false, // ให้คีย์บอร์ดทับได้
        child: SizedBox(
          width: 700,
          height: dialogHeight,
          child: Column(
            children: [
              // ===== Header + ช่องค้นหา (อยู่ใน Scroll เล็ก ๆ เพื่อกันล้นแนวดิ่งสุด ๆ) =====
              Flexible(
                fit: FlexFit.loose,
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(top: math.max(0, topPad - 8)),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'ค้นหากลุ่ม',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              tooltip: 'ปิด',
                            ),
                          ],
                        ),
                      ),

                      // ช่องค้นหาแบบ Floating สวย ๆ
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                        child: Material(
                          elevation: 2,
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  decoration: InputDecoration(
                                    hintText: 'พิมพ์ชื่อกลุ่ม หรือคำค้นหา...',
                                    prefixIcon: const Icon(Icons.search),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  ),
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _performSearch,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: themeTan,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isSearching ||
                                          _searchController.text.trim().isEmpty
                                      ? null
                                      : () => _performSearch(_searchController.text),
                                  child: _isSearching
                                      ? const SizedBox(
                                          width: 18, height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.black),
                                        )
                                      : const Text('ค้นหา',
                                          style: TextStyle(fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ===== ส่วนล่าง (Expanded เดียว) — เลื่อนแทนการล้น =====
              Expanded(
                child: _showSuggestions
                    ? _SuggestionList(
                        names: _nameSuggestions,
                        onTap: (name) {
                          _searchController.text = name;
                          _performSearch(name);
                        },
                      )
                    : _buildResults(themeTan),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(Color themeTan) {
    if (!_hasSearched) {
      return const _EmptyState(
        icon: Icons.search,
        title: 'เริ่มค้นหา',
        subtitle: 'พิมพ์คำค้นหา/ชื่อกลุ่ม แล้วกด Enter หรือปุ่มค้นหา',
      );
    }
    if (_isSearching) {
      return _LoadingState(themeTan: themeTan);
    }
    if (_results.isEmpty) {
      return const _EmptyState(
        icon: Icons.search_off,
        title: 'ไม่พบกลุ่ม',
        subtitle: 'ลองคำอื่นหรือสะกดใหม่อีกครั้ง',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _results.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _GroupTile(group: _results[i]),
    );
  }
}

// ---------- Suggestion: ชื่อกลุ่มอย่างเดียว ----------
class _SuggestionList extends StatelessWidget {
  final List<String> names;
  final ValueChanged<String> onTap;

  const _SuggestionList({
    required this.names,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('ไม่มีคำแนะนำชื่อกลุ่ม', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: names.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
      itemBuilder: (_, i) {
        final s = names[i];
        return ListTile(
          dense: true,
          leading: const Icon(Icons.group),
          title: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () => onTap(s),
        );
      },
    );
  }
}

// ---------- Group Tile ----------
class _GroupTile extends StatelessWidget {
  final CommunityGroup group;
  const _GroupTile({required this.group});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<CommunityProvider>();
    final joined = provider.userGroups.any((g) => g.id == group.id);

    return Material(
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          // TODO: ไปหน้ารายละเอียดกลุ่ม
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _GroupAvatar(url: group.hasCoverImage ? group.coverImage : null),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      group.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[700], height: 1.25),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: provider.isLoading
                    ? null
                    : () async {
                        final ok = joined
                            ? await provider.leaveGroup(group.id)
                            : await provider.joinGroup(group.id);
                        final msg = joined ? 'ออกจากกลุ่มแล้ว' : 'เข้าร่วมกลุ่มแล้ว';
                        final color = joined ? Colors.orange[600] : Colors.green[600];
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok ? msg : 'ทำรายการไม่สำเร็จ'),
                            backgroundColor: ok ? color : Colors.red[600],
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: joined ? Colors.grey[300] : const Color(0xFFD2B48C),
                  foregroundColor: joined ? Colors.grey[800] : Colors.black,
                  minimumSize: const Size(82, 36),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: joined ? 0 : 1,
                ),
                child: Text(joined ? 'ออก' : 'เข้าร่วม',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupAvatar extends StatelessWidget {
  final String? url;
  const _GroupAvatar({this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFD2B48C),
        borderRadius: BorderRadius.circular(26),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? const Icon(Icons.pets, color: Colors.white, size: 26)
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.pets, color: Colors.white, size: 26),
            ),
    );
  }
}

// ---------- Empty/Loading ----------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
            const SizedBox(height: 6),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final Color themeTan;
  const _LoadingState({required this.themeTan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: themeTan),
        const SizedBox(height: 10),
        Text('กำลังค้นหา...', style: TextStyle(color: Colors.grey[700])),
      ]),
    );
  }
}
