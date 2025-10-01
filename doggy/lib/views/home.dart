import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../widgets/slidebar.dart';
import '../widgets/bottom_navbar.dart';
import '../routes/app_routes.dart';
import '../services/home_service.dart';
import '../widgets/app_header.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth = FirebaseAuth.instance;
  final _service = HomeService(firestore: FirebaseFirestore.instance);

  // Data (น้อยลง)
  String? _dogImageRaw;
  Map<String, dynamic>? _continueCourse;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featured = [];

  // Carousel
  late final PageController _pageController;
  Timer? _timer;
  int _currentBanner = 0;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _initFast();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  /// ครอบ future ด้วย timeout: ถ้าช้าเกินไป คืนค่า default ทันที
  Future<T?> _withTimeout<T>(Future<T> f, {int ms = 1500}) async {
    try {
      return await f.timeout(Duration(milliseconds: ms));
    } catch (_) {
      return null;
    }
  }

  Future<void> _initFast() async {
    final user = _auth.currentUser;

    // 1) ดึงชุดแรกแบบขนาดเล็ก + ใส่ timeout (1.5-2.0s)
    final futures = <Future>[];

    if (user != null) {
      futures.add(
          _withTimeout(_service.fetchDogProfileImage(user.uid), ms: 1200)
              .then((v) => _dogImageRaw = v));
      futures.add(_withTimeout(_service.fetchContinueCourse(user.uid), ms: 1500)
          .then((v) => _continueCourse = v));
    }

    futures.add(_withTimeout(_service.fetchFeaturedQuick(limit: 8), ms: 1800)
        .then((v) => _featured = (v ?? [])));

    await Future.wait(futures);

    if (!mounted) return;
    setState(() => _loading = false);

    // 2) แบนเนอร์เริ่ม auto-scroll ถ้ามีข้อมูล
    _startAutoScroll();

    // 3) Lazy-load หมวดหมู่ภายหลัง (ลดแรงโหลดช่วงแรก)
    Future.delayed(const Duration(milliseconds: 500), () async {
      final cats =
          await _withTimeout(_service.fetchCategoriesFast(limit: 6), ms: 1500);
      if (!mounted) return;
      if (cats != null) {
        setState(() => _categories = cats);
      }
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_featured.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      int next = _currentBanner + 1;
      if (next >= _featured.length) next = 0;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOut,
      );
    });
  }

  ImageProvider _dogAvatarImage() {
    if (_dogImageRaw == null || _dogImageRaw!.isEmpty) {
      return const AssetImage('assets/images/dog_profile.jpg');
    }
    if (_dogImageRaw!.startsWith('http')) {
      return NetworkImage(_dogImageRaw!);
    }
    try {
      return MemoryImage(base64Decode(_dogImageRaw!));
    } catch (_) {
      return const AssetImage('assets/images/dog_profile.jpg');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppHeader(
        title: 'หน้าหลัก',
        backgroundColor: Color(0xFFD2B48C),
      ),
      drawer: const SlideBar(),
      body: _loading
          ? const _HomeSkeleton()
          : RefreshIndicator(
              onRefresh: _initFast,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting (เอาค้นหาออกแล้ว)
                    _GreetingRow(
                      userName: user?.displayName ?? 'นักฝึกสุนัข',
                      avatar: _dogAvatarImage(),
                    ),
                    const SizedBox(height: 14),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.play_circle_fill,
                            label: 'คอร์สของฉัน',
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.myCourses),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.menu_book_rounded,
                            label: 'คอร์สทั้งหมด',
                            onTap: () =>
                                Navigator.pushNamed(context, AppRoutes.courses),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Continue Learning (อาจไม่มี)
                    if (_continueCourse != null) ...[
                      _SectionTitle('เรียนต่อ', onSeeAll: () {
                        Navigator.pushNamed(context, AppRoutes.myCourses);
                      }),
                      const SizedBox(height: 10),
                      _ContinueCard(
                        name: _continueCourse!['name'] ?? '',
                        image: _continueCourse!['image'] ?? '',
                        percent: (_continueCourse!['percent'] ?? 0) as int,
                        currentStep:
                            (_continueCourse!['currentStep'] ?? 1) as int,
                        totalSteps:
                            (_continueCourse!['totalSteps'] ?? 0) as int,
                        onResume: () {
                          if ((_continueCourse!['categoryId'] ?? '')
                              .toString()
                              .isEmpty) return;
                          Navigator.pushNamed(
                            context,
                            AppRoutes.trainingDetails,
                            arguments: {
                              'documentId': _continueCourse!['programId'],
                              'categoryId': _continueCourse!['categoryId'],
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Banner carousel
                    if (_featured.isNotEmpty) ...[
                      _SectionTitle('คอร์สแนะนำสำหรับคุณ', onSeeAll: () {
                        Navigator.pushNamed(context, AppRoutes.courses);
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 180,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: _featured.length,
                          onPageChanged: (i) =>
                              setState(() => _currentBanner = i),
                          itemBuilder: (_, i) {
                            final item = _featured[i];
                            return _BannerCard(
                              image: item['image'] ?? '',
                              title: item['name'] ?? '',
                              subtitle:
                                  'ความยาก: ${item['difficulty'] ?? '-'} • ${item['duration'] ?? '-'} นาที',
                              onTap: () {
                                if ((item['categoryId'] ?? '')
                                    .toString()
                                    .isEmpty) return;
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.trainingDetails,
                                  arguments: {
                                    'documentId': item['documentId'],
                                    'categoryId': item['categoryId'],
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: _DotsIndicator(
                          count: _featured.length,
                          index: _currentBanner,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Categories (lazy-loaded)
                    if (_categories.isNotEmpty) ...[
                      _SectionTitle('หมวดหมู่ยอดนิยม', onSeeAll: () {
                        Navigator.pushNamed(context, AppRoutes.courses);
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 96,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) {
                            final c = _categories[i];
                            return _CategoryChip(
                              name: c['name'] ?? '',
                              image: c['image'] ?? '',
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.courses,
                                  arguments: {'categoryId': c['categoryId']},
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

// ===================== WIDGETS =====================

class _GreetingRow extends StatelessWidget {
  final String userName;
  final ImageProvider avatar;
  const _GreetingRow({
    required this.userName,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundImage: avatar,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('สวัสดี, $userName 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('พร้อมฝึกน้องหมาวันนี้หรือยัง?',
                  style: TextStyle(color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE6D6C2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.brown[400]),
              const SizedBox(width: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final String name;
  final String image;
  final int percent;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onResume;

  const _ContinueCard({
    required this.name,
    required this.image,
    required this.percent,
    required this.currentStep,
    required this.totalSteps,
    required this.onResume,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1DC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3B086)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: (image.isNotEmpty)
                ? Image.network(
                    image,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback(),
                  )
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: const Color(0xFFECECEC),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                    'ความคืบหน้า $percent% • ขั้นที่ $currentStep / $totalSteps',
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA4D6A7),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('เรียนต่อ',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 76,
        height: 76,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      );
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final String image;
  final VoidCallback onTap;
  const _CategoryChip(
      {required this.name, required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 140,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE6D6C2)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: (image.isNotEmpty)
                    ? Image.network(
                        image,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imgBox(),
                      )
                    : _imgBox(),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imgBox() => Container(
        width: 42,
        height: 42,
        color: const Color(0xFFEFEFEF),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: Colors.grey),
      );
}

class _BannerCard extends StatelessWidget {
  final String image;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _BannerCard({
    required this.image,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              (image.isNotEmpty)
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: const Color(0xFFEFEFEF)),
                    )
                  : Container(color: const Color(0xFFEFEFEF)),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.black.withOpacity(0.0),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 4),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          )),
                    ],
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

class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 18 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.brown : Colors.brown.withOpacity(0.35),
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionTitle(this.title, {Key? key, this.onSeeAll}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasSeeAll = onSeeAll != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisAlignment: hasSeeAll
            ? MainAxisAlignment.spaceBetween
            : MainAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          if (hasSeeAll)
            TextButton(
              onPressed: onSeeAll,
              child: const Text(
                "ดูทั้งหมด",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.brown,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// =============== Skeleton (เอาแถบค้นหาออกแล้ว) ===============

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bar({double h = 14, double w = 120}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: const Color(0xFFEFEFEF),
            borderRadius: BorderRadius.circular(8),
          ),
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          bar(h: 22, w: 180),
          const SizedBox(height: 10),
          bar(w: 220),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: Container(height: 72, decoration: _b())),
              const SizedBox(width: 10),
              Expanded(child: Container(height: 72, decoration: _b())),
            ],
          ),
          const SizedBox(height: 18),
          bar(w: 200),
          const SizedBox(height: 10),
          Container(height: 180, decoration: _b()),
        ],
      ),
    );
  }

  static BoxDecoration _b() => BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(12),
      );
}
