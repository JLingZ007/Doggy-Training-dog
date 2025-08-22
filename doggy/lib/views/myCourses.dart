import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';

enum CourseFilter { all, inprogress, completed }
enum SortMode { recent, az, progress }

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});

  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProgressService _service =
      ProgressService(firestore: FirebaseFirestore.instance);
  final UserService _userService = UserService();

  CourseFilter _filter = CourseFilter.all;
  SortMode _sort = SortMode.recent;

  String? _activeDogId;
  String? _activeDogName; // ใช้โชว์หัวข้อสวย ๆ

  @override
  void initState() {
    super.initState();
    _loadActiveDogOnce();
    // subscribe เปลี่ยนค่าเมื่อผู้ใช้สลับตัว
    if (_auth.currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .listen((s) {
        final id = s.data()?['activeDogId'] as String?;
        if (mounted) {
          setState(() => _activeDogId = id);
        }
      });
    }
  }

  Future<void> _loadActiveDogOnce() async {
    final u = _auth.currentUser;
    if (u == null) return;
    final id = await _userService.getActiveDogId();
    String? name;
    if (id != null) {
      final dog = await FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .collection('dogs')
          .doc(id)
          .get();
      name = (dog.data() ?? {})['name'] as String?;
    }
    if (mounted) {
      setState(() {
        _activeDogId = id;
        _activeDogName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('กรุณาเข้าสู่ระบบก่อน')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('บทเรียนของฉัน', style: TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'เลือกสุนัข',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.dogProfiles),
            icon: const Icon(Icons.pets, color: Colors.black),
          )
        ],
      ),
      body: (_activeDogId == null)
          ? _NoDogBanner(onChoose: () {
              Navigator.pushNamed(context, AppRoutes.dogProfiles);
            })
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.streamDogProgress(
                userId: user.uid,
                dogId: _activeDogId!,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(
                    dogName: _activeDogName,
                    onBrowse: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ยังไม่มีประวัติการฝึก')),
                      );
                    },
                  );
                }

                // map -> item
                final items = docs.map((d) {
                  final data = d.data();
                  return _CourseItem(
                    programId: d.id,
                    name: (data['name'] ?? 'ไม่ทราบชื่อ').toString(),
                    image: (data['image'] ?? '').toString(),
                    percent: _service.asInt(data['progressPercent']),
                    totalSteps: _service.asInt(data['totalSteps']),
                    currentStep: _service.asInt(data['currentStep'], 1),
                    categoryId: (data['categoryId'] ?? '').toString(),
                    updatedAt: (data['updatedAt'] is Timestamp)
                        ? (data['updatedAt'] as Timestamp).toDate()
                        : null,
                    completedAt: (data['completedAt'] is Timestamp)
                        ? (data['completedAt'] as Timestamp).toDate()
                        : null,
                  );
                }).toList();

                // filter
                List<_CourseItem> filtered = items.where((e) {
                  final done = _service.isCompleted(e.percent);
                  switch (_filter) {
                    case CourseFilter.all:
                      return true;
                    case CourseFilter.inprogress:
                      return !done;
                    case CourseFilter.completed:
                      return done;
                  }
                }).toList();

                // sort
                filtered.sort((a, b) {
                  switch (_sort) {
                    case SortMode.recent:
                      final ta = a.updatedAt?.millisecondsSinceEpoch ?? 0;
                      final tb = b.updatedAt?.millisecondsSinceEpoch ?? 0;
                      return tb.compareTo(ta); // ใหม่→เก่า
                    case SortMode.az:
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    case SortMode.progress:
                      final pc = b.percent.compareTo(a.percent); // มาก→น้อย
                      if (pc != 0) return pc;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  }
                });

                // stats
                final total = items.length;
                final completed = items.where((e) => e.percent >= 100).length;
                final inprogress = total - completed;

                return Column(
                  children: [
                    _HeaderStatsWithDog(
                      dogName: _activeDogName,
                      total: total,
                      inprogress: inprogress,
                      completed: completed,
                      onChangeDog: () =>
                          Navigator.pushNamed(context, AppRoutes.dogProfiles),
                    ),
                    _FiltersBar(
                      filter: _filter,
                      onFilterChanged: (f) => setState(() => _filter = f),
                      sort: _sort,
                      onSortChanged: (s) => setState(() => _sort = s),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final c = filtered[index];
                          final isDone = c.percent >= 100;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 3,
                            shadowColor: Colors.black26,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _openCourse(context, c),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: (c.image.isNotEmpty)
                                          ? Image.network(
                                              c.image,
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _fallbackBox(),
                                            )
                                          : _fallbackBox(width: 70, height: 70),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  c.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _MoreMenu(
                                                onReset: () =>
                                                    _confirmReset(context, c),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value:
                                                  (c.percent / 100).clamp(0, 1),
                                              minHeight: 8,
                                              backgroundColor:
                                                  const Color(0xFFECECEC),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text('${c.percent}%'),
                                              const Spacer(),
                                              Text(
                                                  'ขั้นที่ ${c.currentStep} / ${c.totalSteps}'),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Icon(
                                                isDone
                                                    ? Icons.verified
                                                    : Icons.history,
                                                size: 16,
                                                color: isDone
                                                    ? Colors.green
                                                    : Colors.brown[400],
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  isDone
                                                      ? _fmtCompleted(
                                                          c.completedAt)
                                                      : _fmtUpdated(
                                                          c.updatedAt),
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.black54),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () =>
                                                      _openCourse(context, c),
                                                  icon: Icon(isDone
                                                      ? Icons.replay
                                                      : Icons.play_arrow),
                                                  label: Text(isDone
                                                      ? 'ทบทวน'
                                                      : 'เรียนต่อ'),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(
                                                            0xFFA4D6A7),
                                                    foregroundColor:
                                                        Colors.black,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 10),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  void _openCourse(BuildContext context, _CourseItem c) {
    if (c.categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบหมวดบทเรียน')),
      );
      return;
    }
    Navigator.pushNamed(
      context,
      AppRoutes.trainingDetails,
      arguments: {
        'documentId': c.programId,
        'categoryId': c.categoryId,
        'dogId': _activeDogId, // ← ส่ง dogId ไปด้วย
      },
    );
  }

  Future<void> _confirmReset(BuildContext context, _CourseItem c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('เริ่มบทเรียนนี้ใหม่?'),
        content: Text('รีเซ็ตความคืบหน้าของ\n"${c.name}" ทั้งหมด'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ยกเลิก')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ยืนยัน')),
        ],
      ),
    );
    if (ok == true) {
      final user = _auth.currentUser!;
      await _service.resetCourse(
        userId: user.uid,
        dogId: _activeDogId!, // ← รีเซ็ตของสุนัขตัวนี้
        programId: c.programId,
        categoryId: c.categoryId,
        totalSteps: c.totalSteps,
        name: c.name,
        image: c.image,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('รีเซ็ตแล้ว')),
        );
      }
    }
  }

  String _fmtUpdated(DateTime? dt) {
    if (dt == null) return 'อัปเดตล่าสุด: -';
    return 'อัปเดตล่าสุด: ${_fmtDate(dt)}';
  }

  String _fmtCompleted(DateTime? dt) {
    if (dt == null) return 'สำเร็จแล้ว';
    return 'สำเร็จเมื่อ: ${_fmtDate(dt)}';
  }

  String _fmtDate(DateTime dt) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Widget _fallbackBox({double width = 70, double height = 70}) => Container(
        width: width,
        height: height,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: Colors.grey),
      );
}

/// ----- Widgets เฉพาะหน้านี้ ----- ///
class _HeaderStatsWithDog extends StatelessWidget {
  final String? dogName;
  final int total;
  final int inprogress;
  final int completed;
  final VoidCallback onChangeDog;

  const _HeaderStatsWithDog({
    required this.dogName,
    required this.total,
    required this.inprogress,
    required this.completed,
    required this.onChangeDog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7EFE6),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogName == null ? 'สุนัข: -' : 'สุนัข: $dogName',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'ทั้งหมด', value: total),
                    _StatChip(label: 'กำลังเรียน', value: inprogress),
                    _StatChip(label: 'สำเร็จ', value: completed),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChangeDog,
            icon: const Icon(Icons.pets),
            label: const Text('เปลี่ยนสุนัข'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label:
          Text('$label: $value', style: const TextStyle(fontWeight: FontWeight.w600)),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: const Color(0xFFFFFFFF),
      side: const BorderSide(color: Color(0xFFE6D6C2)),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  final CourseFilter filter;
  final ValueChanged<CourseFilter> onFilterChanged;
  final SortMode sort;
  final ValueChanged<SortMode> onSortChanged;

  const _FiltersBar({
    required this.filter,
    required this.onFilterChanged,
    required this.sort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      color: const Color(0xFFFDF9F4),
      child: Row(
        children: [
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _seg('ทั้งหมด', CourseFilter.all),
                _seg('กำลังเรียน', CourseFilter.inprogress),
                _seg('สำเร็จ', CourseFilter.completed),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<SortMode>(
            initialValue: sort,
            onSelected: onSortChanged,
            itemBuilder: (context) => [
              _mi('ล่าสุด', SortMode.recent),
              _mi('A → Z', SortMode.az),
              _mi('ความคืบหน้า', SortMode.progress),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.sort),
                SizedBox(width: 4),
                Text('จัดเรียง'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortMode> _mi(String label, SortMode val) =>
      PopupMenuItem(value: val, child: Text(label));

  Widget _seg(String text, CourseFilter val) {
    final selected = val == filter;
    return GestureDetector(
      onTap: () => onFilterChanged(val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEBC7A6) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFFE3B086) : const Color(0xFFE6D6C2),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black : Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  final VoidCallback onReset;
  const _MoreMenu({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) {
        if (v == 'reset') onReset();
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'reset',
          child: Text('เริ่มใหม่ (รีเซ็ตความคืบหน้า)'),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String? dogName;
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse, this.dogName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.pets, size: 60, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              dogName == null
                  ? 'ยังไม่มีประวัติการฝึก'
                  : 'ยังไม่มีประวัติการฝึกของ $dogName',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onBrowse,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA4D6A7),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('ไปดูบทเรียนที่แนะนำ'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoDogBanner extends StatelessWidget {
  final VoidCallback onChoose;
  const _NoDogBanner({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1DC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD9A3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'ยังไม่ได้เลือกสุนัขที่ติดตาม',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'เลือกสุนัขตัวที่ต้องการติดตามเพื่อดูความคืบหน้าบทเรียน',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: onChoose,
                    icon: const Icon(Icons.pets),
                    label: const Text('เลือกสุนัข'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- Model ภายในหน้า ----------------
class _CourseItem {
  final String programId;
  final String name;
  final String image;
  final int percent;
  final int totalSteps;
  final int currentStep;
  final String categoryId;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  _CourseItem({
    required this.programId,
    required this.name,
    required this.image,
    required this.percent,
    required this.totalSteps,
    required this.currentStep,
    required this.categoryId,
    required this.updatedAt,
    required this.completedAt,
  });
}
