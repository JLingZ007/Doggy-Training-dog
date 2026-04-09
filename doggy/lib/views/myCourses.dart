import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../routes/app_routes.dart';
import '../services/progress_service.dart';
import '../services/user_service.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const kBgColor      = Color(0xFFF7EFE7);
const kSurfaceCream = Color(0xFFEFE2D3);
const kFieldCream   = Color(0xFFEAD8C8);
const kLightPaw     = Color(0xFFE8D5C0);
const kPrimaryBrown = Color(0xFFB08968);
const kDarkBrown    = Color(0xFF6D4C41);
const kCancelColor  = Color(0xFF7C5959);
const kSuccessGreen = Color(0xFF4C9A5C);
const kSuccessBg    = Color(0xFFEDF6EE);
const kSuccessBorder= Color(0xFFC3E6CB);

enum CourseFilter { all, inprogress, completed }
enum SortMode { recent, az, progress }

class MyCoursesPage extends StatefulWidget {
  const MyCoursesPage({super.key});
  @override
  State<MyCoursesPage> createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final _auth        = FirebaseAuth.instance;
  final _service     = ProgressService(firestore: FirebaseFirestore.instance);
  final _userService = UserService();

  CourseFilter _filter = CourseFilter.all;
  SortMode     _sort   = SortMode.recent;

  String? _activeDogId;
  String? _activeDogName;

  @override
  void initState() {
    super.initState();
    _loadActiveDogOnce();
    if (_auth.currentUser != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .snapshots()
          .listen((s) {
        final id = s.data()?['activeDogId'] as String?;
        if (mounted) setState(() => _activeDogId = id);
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
    if (mounted) setState(() { _activeDogId = id; _activeDogName = name; });
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _fmtDate(DateTime dt) {
    final p = (int n) => n.toString().padLeft(2, '0');
    return '${p(dt.day)}/${p(dt.month)}/${dt.year}';
  }

  String _fmtUpdated(DateTime? dt) =>
      dt == null ? 'อัปเดตล่าสุด: -' : 'อัปเดต ${_fmtDate(dt)}';

  String _fmtCompleted(DateTime? dt) =>
      dt == null ? 'สำเร็จแล้ว' : 'สำเร็จ ${_fmtDate(dt)}';

  void _openCourse(BuildContext context, _CourseItem c) {
    if (c.categoryId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบหมวดบทเรียน')));
      return;
    }
    Navigator.pushNamed(context, AppRoutes.trainingDetails, arguments: {
      'documentId': c.programId,
      'categoryId': c.categoryId,
      'dogId': _activeDogId,
    });
  }

  Future<void> _confirmReset(BuildContext context, _CourseItem c) async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kLightPaw),
          ),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1DC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFDEA0)),
                ),
                child: const Icon(Icons.restart_alt_rounded,
                    size: 26, color: Color(0xFFB07D00)),
              ),
              const SizedBox(height: 14),
              const Text('เริ่มบทเรียนนี้ใหม่?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kDarkBrown)),
              const SizedBox(height: 8),
              Text('รีเซ็ตความคืบหน้าของ\n"${c.name}" ทั้งหมด',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13,
                      color: kPrimaryBrown,
                      height: 1.6,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kCancelColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('ยืนยันรีเซ็ต'),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                    foregroundColor: kPrimaryBrown,
                    textStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      final user = _auth.currentUser!;
      await _service.resetCourse(
        userId: user.uid,
        dogId: _activeDogId!,
        programId: c.programId,
        categoryId: c.categoryId,
        totalSteps: c.totalSteps,
        name: c.name,
        image: c.image,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('รีเซ็ตแล้ว'),
            backgroundColor: kPrimaryBrown,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: kBgColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline_rounded,
                  size: 48, color: kPrimaryBrown),
              const SizedBox(height: 12),
              const Text('กรุณาเข้าสู่ระบบก่อน',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kDarkBrown)),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
  backgroundColor: Colors.white,
  elevation: 0,
  centerTitle: true,
  toolbarHeight: 56,
  leadingWidth: 56,
  leading: GestureDetector(
    onTap: () => Navigator.pop(context),
    child: Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: kSurfaceCream,
          shape: BoxShape.circle,
          border: Border.all(color: kLightPaw),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 15,
          color: kDarkBrown,
        ),
      ),
    ),
  ),
  title: const Text(
    'บทเรียนของฉัน',
    style: TextStyle(
      color: kDarkBrown,
      fontWeight: FontWeight.w800,
      fontSize: 16,
      letterSpacing: -0.2,
    ),
  ),
  actions: [
    Center(
      child: GestureDetector(
        onTap: () async {
        // ✅ รอ result จาก dog_profiles.dart
        final changed = await Navigator.pushNamed(
            context, AppRoutes.dogProfiles);
        // ถ้ามีการเปลี่ยนสุนัข ให้ reload ข้อมูล
        if (changed == true && mounted) {
          _loadActiveDogOnce();
        }
      },
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(
              horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: kSurfaceCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLightPaw),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.pets_rounded,
                  size: 13, color: kPrimaryBrown),
              SizedBox(width: 5),
              Text(
                'เปลี่ยนสุนัข',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kDarkBrown,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ],
),
      body: _activeDogId == null
          ? _NoDogBanner(
  onChoose: () async {
    final changed = await Navigator.pushNamed(
        context, AppRoutes.dogProfiles);
    if (changed == true && mounted) {
      _loadActiveDogOnce();
    }
  },
)
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.streamDogProgress(
                  userId: user.uid, dogId: _activeDogId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryBrown, strokeWidth: 2.5));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _EmptyState(
                    dogName: _activeDogName,
                    onBrowse: () => Navigator.pushNamed(
                        context, AppRoutes.courses),
                  );
                }

                final items = docs.map((d) {
                  final data = d.data();
                  return _CourseItem(
                    programId: d.id,
                    name: (data['name'] ?? 'ไม่ทราบชื่อ').toString(),
                    image: (data['image'] ?? '').toString(),
                    percent: _service.asInt(data['progressPercent']),
                    totalSteps: _service.asInt(data['totalSteps']),
                    currentStep:
                        _service.asInt(data['currentStep'], 1),
                    categoryId:
                        (data['categoryId'] ?? '').toString(),
                    updatedAt: (data['updatedAt'] is Timestamp)
                        ? (data['updatedAt'] as Timestamp).toDate()
                        : null,
                    completedAt: (data['completedAt'] is Timestamp)
                        ? (data['completedAt'] as Timestamp).toDate()
                        : null,
                  );
                }).toList();

                // filter
                final filtered = items.where((e) {
                  final done = _service.isCompleted(e.percent);
                  return switch (_filter) {
                    CourseFilter.all        => true,
                    CourseFilter.inprogress => !done,
                    CourseFilter.completed  => done,
                  };
                }).toList()
                  ..sort((a, b) => switch (_sort) {
                        SortMode.recent => (b.updatedAt
                                    ?.millisecondsSinceEpoch ??
                                0)
                            .compareTo(a.updatedAt
                                    ?.millisecondsSinceEpoch ??
                                0),
                        SortMode.az => a.name
                            .toLowerCase()
                            .compareTo(b.name.toLowerCase()),
                        SortMode.progress => b.percent != a.percent
                            ? b.percent.compareTo(a.percent)
                            : a.name
                                .toLowerCase()
                                .compareTo(b.name.toLowerCase()),
                      });

                final total =
                    items.length;
                final completed =
                    items.where((e) => e.percent >= 100).length;
                final inprogress = total - completed;

                return Column(
                  children: [
                    // ── Header stats ────────────────────────────────────
                    _HeaderStats(
                      dogName: _activeDogName,
                      total: total,
                      inprogress: inprogress,
                      completed: completed,
                      onChangeDog: () => Navigator.pushNamed(
                          context, AppRoutes.dogProfiles),
                    ),

                    // ── Filter + Sort bar ────────────────────────────────
                    _FilterSortBar(
                      filter: _filter,
                      onFilterChanged: (f) =>
                          setState(() => _filter = f),
                      sort: _sort,
                      onSortChanged: (s) => setState(() => _sort = s),
                    ),

                    const SizedBox(height: 4),

                    // ── Course list ──────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _FilterEmpty(filter: _filter)
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                  14, 4, 14, 20),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final c = filtered[i];
                                return _CourseCard(
                                  item: c,
                                  fmtUpdated: _fmtUpdated,
                                  fmtCompleted: _fmtCompleted,
                                  onTap: () =>
                                      _openCourse(context, c),
                                  onReset: () =>
                                      _confirmReset(context, c),
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
}

// ─── Header Stats ─────────────────────────────────────────────────────────────
class _HeaderStats extends StatelessWidget {
  final String? dogName;
  final int total;
  final int inprogress;
  final int completed;
  final VoidCallback onChangeDog;

  const _HeaderStats({
    required this.dogName,
    required this.total,
    required this.inprogress,
    required this.completed,
    required this.onChangeDog,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDarkBrown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kPrimaryBrown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets_rounded,
                size: 24, color: kLightPaw),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dogName == null
                      ? 'ยังไม่ได้เลือกสุนัข'
                      : dogName!,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.2),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _MiniStat(
                        label: 'ทั้งหมด',
                        value: total,
                        color: kLightPaw),
                    const SizedBox(width: 8),
                    _MiniStat(
                        label: 'กำลังเรียน',
                        value: inprogress,
                        color: const Color(0xFFFFF1DC)),
                    const SizedBox(width: 8),
                    _MiniStat(
                        label: 'สำเร็จ',
                        value: completed,
                        color: kSuccessBg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _MiniStat(
      {required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: color)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.85))),
        ],
      ),
    );
  }
}

// ─── Filter + Sort Bar ────────────────────────────────────────────────────────
class _FilterSortBar extends StatelessWidget {
  final CourseFilter filter;
  final ValueChanged<CourseFilter> onFilterChanged;
  final SortMode sort;
  final ValueChanged<SortMode> onSortChanged;

  const _FilterSortBar({
    required this.filter,
    required this.onFilterChanged,
    required this.sort,
    required this.onSortChanged,
  });

  static const _labels = {
    CourseFilter.all:        'ทั้งหมด',
    CourseFilter.inprogress: 'กำลังเรียน',
    CourseFilter.completed:  'สำเร็จ',
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        children: [
          // Segmented filter
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: kSurfaceCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kLightPaw),
              ),
              child: Row(
                children: CourseFilter.values.map((f) {
                  final selected = f == filter;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onFilterChanged(f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: selected ? kDarkBrown : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _labels[f]!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : kPrimaryBrown,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Sort popup
          PopupMenuButton<SortMode>(
            initialValue: sort,
            onSelected: onSortChanged,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            itemBuilder: (_) => [
              _sortItem('ล่าสุด', Icons.access_time_rounded,
                  SortMode.recent),
              _sortItem('A → Z', Icons.sort_by_alpha_rounded,
                  SortMode.az),
              _sortItem('ความคืบหน้า',
                  Icons.show_chart_rounded, SortMode.progress),
            ],
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kSurfaceCream,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kLightPaw),
              ),
              child: const Icon(Icons.tune_rounded,
                  size: 18, color: kDarkBrown),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<SortMode> _sortItem(
      String label, IconData icon, SortMode val) {
    return PopupMenuItem(
      value: val,
      child: Row(
        children: [
          Icon(icon, size: 16, color: kPrimaryBrown),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kDarkBrown)),
        ],
      ),
    );
  }
}

// ─── Course Card ──────────────────────────────────────────────────────────────
class _CourseCard extends StatelessWidget {
  final _CourseItem item;
  final String Function(DateTime?) fmtUpdated;
  final String Function(DateTime?) fmtCompleted;
  final VoidCallback onTap;
  final VoidCallback onReset;

  const _CourseCard({
    required this.item,
    required this.fmtUpdated,
    required this.fmtCompleted,
    required this.onTap,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = item.percent >= 100;
    final progress = (item.percent / 100).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDone ? kSuccessBorder : kLightPaw,
          width: isDone ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBrown.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Top row: image + info + menu ────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: item.image.isNotEmpty
                          ? Image.network(
                              item.image,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _thumbFallback(),
                            )
                          : _thumbFallback(),
                    ),
                    const SizedBox(width: 12),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: kDarkBrown,
                                    height: 1.3,
                                    letterSpacing: -0.1,
                                  ),
                                ),
                              ),
                              // More menu
                              SizedBox(
                                width: 28,
                                height: 28,
                                child: PopupMenuButton<String>(
                                  padding: EdgeInsets.zero,
                                  onSelected: (v) {
                                    if (v == 'reset') onReset();
                                  },
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'reset',
                                      child: Row(
                                        children: const [
                                          Icon(
                                              Icons.restart_alt_rounded,
                                              size: 16,
                                              color: kCancelColor),
                                          SizedBox(width: 8),
                                          Text('รีเซ็ตความคืบหน้า',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: kDarkBrown)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  icon: const Icon(
                                      Icons.more_vert_rounded,
                                      size: 18,
                                      color: kPrimaryBrown),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 7,
                              backgroundColor: kFieldCream,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone
                                    ? kSuccessGreen
                                    : kPrimaryBrown,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Percent + steps
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? kSuccessBg
                                      : kFieldCream,
                                  borderRadius:
                                      BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${item.percent}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: isDone
                                        ? kSuccessGreen
                                        : kDarkBrown,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ขั้นที่ ${item.currentStep} / ${item.totalSteps}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: kPrimaryBrown,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: kLightPaw, thickness: 1, height: 1),
                const SizedBox(height: 10),

                // ── Bottom row: date + action button ────────────────────
                Row(
                  children: [
                    Icon(
                      isDone
                          ? Icons.check_circle_rounded
                          : Icons.access_time_rounded,
                      size: 14,
                      color: isDone ? kSuccessGreen : kPrimaryBrown,
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        isDone
                            ? fmtCompleted(item.completedAt)
                            : fmtUpdated(item.updatedAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: kPrimaryBrown,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Action button
                    ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDone ? kSurfaceCream : kDarkBrown,
                        foregroundColor:
                            isDone ? kDarkBrown : Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                        minimumSize: Size.zero,
                        tapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isDone
                                ? Icons.replay_rounded
                                : Icons.play_arrow_rounded,
                            size: 14),
                          const SizedBox(width: 4),
                          Text(isDone ? 'ทบทวน' : 'เรียนต่อ'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: kFieldCream,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
            child:
                Icon(Icons.pets_rounded, color: kPrimaryBrown, size: 28)),
      );
}

// ─── Filter Empty ─────────────────────────────────────────────────────────────
class _FilterEmpty extends StatelessWidget {
  final CourseFilter filter;
  const _FilterEmpty({required this.filter});

  @override
  Widget build(BuildContext context) {
    final label = filter == CourseFilter.inprogress
        ? 'ไม่มีบทเรียนที่กำลังเรียน'
        : 'ไม่มีบทเรียนที่สำเร็จแล้ว';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list_off_rounded,
              size: 40, color: kLightPaw),
          const SizedBox(height: 10),
          Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kPrimaryBrown)),
        ],
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String? dogName;
  final VoidCallback onBrowse;
  const _EmptyState({required this.onBrowse, this.dogName});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                  color: kSurfaceCream, shape: BoxShape.circle),
              child: const Icon(Icons.pets_rounded,
                  size: 44, color: kPrimaryBrown),
            ),
            const SizedBox(height: 16),
            Text(
              dogName == null
                  ? 'ยังไม่มีประวัติการฝึก'
                  : 'ยังไม่มีบทเรียนของ $dogName',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: kDarkBrown),
            ),
            const SizedBox(height: 8),
            const Text(
              'เริ่มฝึกสุนัขของคุณด้วยบทเรียนที่แนะนำ',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13,
                  color: kPrimaryBrown,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onBrowse,
              icon: const Icon(Icons.school_rounded, size: 16),
              label: const Text('ดูบทเรียนทั้งหมด'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kDarkBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── No Dog Banner ────────────────────────────────────────────────────────────
class _NoDogBanner extends StatelessWidget {
  final VoidCallback onChoose;
  const _NoDogBanner({required this.onChoose});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: kLightPaw),
            boxShadow: [
              BoxShadow(
                color: kPrimaryBrown.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                    color: kSurfaceCream, shape: BoxShape.circle),
                child: const Icon(Icons.pets_rounded,
                    size: 32, color: kPrimaryBrown),
              ),
              const SizedBox(height: 14),
              const Text('ยังไม่ได้เลือกสุนัข',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: kDarkBrown)),
              const SizedBox(height: 8),
              const Text(
                'เลือกสุนัขเพื่อดูความคืบหน้า\nการฝึกของแต่ละตัว',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13,
                    color: kPrimaryBrown,
                    height: 1.6,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onChoose,
                  icon: const Icon(Icons.pets_rounded, size: 16),
                  label: const Text('เลือกสุนัข'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    textStyle: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Model ────────────────────────────────────────────────────────────────────
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