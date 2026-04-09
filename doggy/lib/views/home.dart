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

// ─── Design Tokens ────────────────────────────────────────────────────────────
const kBgColor      = Color(0xFFF7EFE7);
const kSurfaceCream = Color(0xFFEFE2D3);
const kFieldCream   = Color(0xFFEAD8C8);
const kCancelColor  = Color(0xFF7C5959);
const kPrimaryBrown = Color(0xFFB08968);
const kDarkBrown    = Color(0xFF6D4C41);
const kLightPaw     = Color(0xFFE8D5C0);
const kCardWhite    = Colors.white;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _auth    = FirebaseAuth.instance;
  final _service = HomeService(firestore: FirebaseFirestore.instance);

  String? _dogImageRaw;
  Map<String, dynamic>? _continueCourse;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _featured   = [];

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

  Future<T?> _withTimeout<T>(Future<T> f, {int ms = 1500}) async {
    try {
      return await f.timeout(Duration(milliseconds: ms));
    } catch (_) {
      return null;
    }
  }

  Future<void> _initFast() async {
    final user = _auth.currentUser;
    final futures = <Future>[];

    if (user != null) {
      futures.add(
        _withTimeout(_service.fetchDogProfileImage(user.uid), ms: 1200)
            .then((v) => _dogImageRaw = v));
      futures.add(
        _withTimeout(_service.fetchContinueCourse(user.uid), ms: 1500)
            .then((v) => _continueCourse = v));
    }

    futures.add(
      _withTimeout(_service.fetchFeaturedQuick(limit: 8), ms: 1800)
          .then((v) => _featured = (v ?? [])));

    await Future.wait(futures);
    if (!mounted) return;
    setState(() => _loading = false);
    _startAutoScroll();

    Future.delayed(const Duration(milliseconds: 500), () async {
      final cats = await _withTimeout(
          _service.fetchCategoriesFast(limit: 6), ms: 1500);
      if (!mounted) return;
      if (cats != null) setState(() => _categories = cats);
    });
  }

  void _startAutoScroll() {
    _timer?.cancel();
    if (_featured.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;
      int next = (_currentBanner + 1) % _featured.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 460),
        curve: Curves.easeInOut,
      );
    });
  }

  ImageProvider _dogAvatarImage() {
    if (_dogImageRaw == null || _dogImageRaw!.isEmpty) {
      return const AssetImage('assets/images/dog_profiles.png');
    }
    if (_dogImageRaw!.startsWith('http')) return NetworkImage(_dogImageRaw!);
    try {
      return MemoryImage(base64Decode(_dogImageRaw!));
    } catch (_) {
      return const AssetImage('assets/images/dog_profiles.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppHeader(
        title: 'หน้าหลัก',
        backgroundColor: kSurfaceCream,
      ),
      drawer: const SlideBar(),
      body: _loading
          ? const _HomeSkeleton()
          : RefreshIndicator(
              color: kPrimaryBrown,
              onRefresh: _initFast,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Greeting ──────────────────────────────────────────
                    _GreetingCard(
                      userName: user?.displayName ?? 'นักฝึกสุนัข',
                      avatar: _dogAvatarImage(),
                    ),
                    const SizedBox(height: 16),

                    // ── Quick Actions ──────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.play_circle_fill_rounded,
                            label: 'คอร์สของฉัน',
                            color: const Color(0xFFFFF1DC),
                            iconColor: const Color(0xFFE07B39),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.myCourses),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.menu_book_rounded,
                            label: 'คอร์สทั้งหมด',
                            color: const Color(0xFFEDF6EE),
                            iconColor: const Color(0xFF4C9A5C),
                            onTap: () => Navigator.pushNamed(
                                context, AppRoutes.courses),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── Continue Learning ──────────────────────────────────
                    if (_continueCourse != null) ...[
                      _SectionHeader(
                        title: 'เรียนต่อจากเดิม',
                        icon: Icons.history_edu_rounded,
                        onSeeAll: () =>
                            Navigator.pushNamed(context, AppRoutes.myCourses),
                      ),
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
                      const SizedBox(height: 20),
                    ],

                    // ── Featured Carousel ──────────────────────────────────
                    if (_featured.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'คอร์สแนะนำ',
                        icon: Icons.star_rounded,
                        onSeeAll: () =>
                            Navigator.pushNamed(context, AppRoutes.courses),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 190,
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
                      const SizedBox(height: 20),
                    ],

                    // ── Categories ─────────────────────────────────────────
                    if (_categories.isNotEmpty) ...[
                      _SectionHeader(
                        title: 'หมวดหมู่ยอดนิยม',
                        icon: Icons.grid_view_rounded,
                        onSeeAll: () =>
                            Navigator.pushNamed(context, AppRoutes.courses),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: _categories.length,
                        itemBuilder: (_, i) {
                          final c = _categories[i];
                          return _CategoryCard(
                            name: c['name'] ?? '',
                            image: c['image'] ?? '',
                            onTap: () => Navigator.pushNamed(
                              context,
                              AppRoutes.courses,
                              arguments: {'categoryId': c['categoryId']},
                            ),
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

// ─── Greeting Card ────────────────────────────────────────────────────────────
class _GreetingCard extends StatelessWidget {
  final String userName;
  final ImageProvider avatar;
  const _GreetingCard({required this.userName, required this.avatar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kDarkBrown,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Avatar with paw ring
          Container(
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: kLightPaw, width: 2),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundImage: avatar,
              backgroundColor: kFieldCream,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สวัสดี, $userName 👋',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'พร้อมฝึกน้องหมาวันนี้หรือยัง?',
                  style: TextStyle(
                    fontSize: 12,
                    color: kLightPaw,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Paw badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kPrimaryBrown.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.pets, color: kLightPaw, size: 20),
          ),
        ],
      ),
    );
  }
}

// ─── Quick Action Card ────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: iconColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 18, color: iconColor),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kSurfaceCream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: kCancelColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: kDarkBrown,
            letterSpacing: -0.2,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kSurfaceCream,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kLightPaw),
              ),
              child: const Text(
                'ดูทั้งหมด →',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: kDarkBrown,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Continue Card ────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLightPaw),
        boxShadow: [
          BoxShadow(
            color: kPrimaryBrown.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: image.isNotEmpty
                ? Image.network(image,
                    width: 74, height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imgFallback())
                : _imgFallback(),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: kDarkBrown,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (percent / 100).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: kFieldCream,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(kPrimaryBrown),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$percent% • ขั้นที่ $currentStep / $totalSteps',
                  style: const TextStyle(
                    fontSize: 12,
                    color: kPrimaryBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Resume button
          ElevatedButton(
            onPressed: onResume,
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkBrown,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            child: const Text('เรียนต่อ'),
          ),
        ],
      ),
    );
  }

  Widget _imgFallback() => Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          color: kFieldCream,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.pets, color: kPrimaryBrown, size: 28),
      );
}

// ─── Banner Card ──────────────────────────────────────────────────────────────
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: kDarkBrown.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: kSurfaceCream),
                    )
                  : Container(color: kSurfaceCream,
                      child: const Center(
                        child: Icon(Icons.pets, color: kPrimaryBrown, size: 40),
                      )),
              // Gradient overlay
              Positioned(
                left: 0, right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        kDarkBrown.withOpacity(0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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
    );
  }
}

// ─── Category Card ────────────────────────────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final String name;
  final String image;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.name,
    required this.image,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kCardWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kLightPaw),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: kFieldCream,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: image.isNotEmpty
                      ? Image.network(image, fit: BoxFit.cover)
                      : const Icon(Icons.pets, color: kPrimaryBrown),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: kDarkBrown,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Dots Indicator ───────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count;
  final int index;
  const _DotsIndicator({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 20 : 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? kDarkBrown : kLightPaw,
            borderRadius: BorderRadius.circular(99),
          ),
        );
      }),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Shimmer(height: 74, radius: 20),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _Shimmer(height: 66, radius: 16)),
            const SizedBox(width: 12),
            Expanded(child: _Shimmer(height: 66, radius: 16)),
          ]),
          const SizedBox(height: 20),
          _Shimmer(height: 16, width: 130, radius: 8),
          const SizedBox(height: 10),
          _Shimmer(height: 100, radius: 18),
          const SizedBox(height: 20),
          _Shimmer(height: 16, width: 130, radius: 8),
          const SizedBox(height: 10),
          _Shimmer(height: 190, radius: 18),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;
  const _Shimmer({required this.height, this.width, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: kFieldCream,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}