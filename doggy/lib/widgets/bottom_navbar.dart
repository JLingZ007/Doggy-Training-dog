import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _kNavBg       = Color(0xFFEFE2D3);
const _kActive      = Color(0xFF6D4C41);
const _kInactive    = Color(0xFFB08968);
const _kIndicator   = Color(0xFFE8D5C0);
const _kLightPaw    = Color(0xFFE8D5C0);
const _kSurface     = Color(0xFFEFE2D3);
const _kFieldCream  = Color(0xFFEAD8C8);
const _kPrimaryBrown= Color(0xFFB08968);
const _kDarkBrown   = Color(0xFF6D4C41);

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTap,
  });

  static const _navItems = [
    _NavItem(
      label: 'หน้าหลัก',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      route: AppRoutes.home,
    ),
    _NavItem(
      label: 'คอร์สเรียน',
      icon: Icons.school_outlined,
      activeIcon: Icons.school_rounded,
      route: AppRoutes.courses,
    ),
    _NavItem(
      label: 'ชุมชน',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      route: AppRoutes.community,
      requireLogin: true,
    ),
    _NavItem(
      label: 'แชทบอท',
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      route: AppRoutes.chat,
      requireLogin: true,
    ),
  ];

  // ── Resolve active index from current route ──────────────────────────────
  int _resolveIndex(String? route) {
    switch (route) {
      case AppRoutes.home:      return 0;
      case AppRoutes.courses:   return 1;
      case AppRoutes.community: return 2;
      case AppRoutes.chat:      return 3;
      default:                  return currentIndex;
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────
void _navigate(BuildContext context, int index) {
  final route = _navItems[index].route;
  if (ModalRoute.of(context)?.settings.name != route) {
    Navigator.pushReplacementNamed(context, route);
  }
}

@override
Widget build(BuildContext context) {
  final user         = FirebaseAuth.instance.currentUser;
  final displayIndex = _resolveIndex(
      ModalRoute.of(context)?.settings.name);

  return Container(
    decoration: BoxDecoration(
      color: _kNavBg,
      border: const Border(
        top: BorderSide(color: _kLightPaw, width: 1),
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF6D4C41).withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, -3),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: SizedBox(
        height: 60,
        child: Row(
          children: List.generate(_navItems.length, (i) {
            final item      = _navItems[i];
            final isActive  = displayIndex == i;
            final showBadge = item.requireLogin && user == null;

            return Expanded(
              child: _NavButton(
                item: item,
                isActive: isActive,
                showBadge: showBadge,
                onTap: () {
  if (item.requireLogin && user == null) {
    _showLoginDialog(context, item); // ✅ ตรงนี้
  } else if (onTap != null) {
    onTap!(i);
  } else {
    _navigate(context, i);
  }
},
              ),
            );
          }),
        ),
      ),
    ),
  );
}

// ── Login required dialog ─────────────────────────────────────────────────
void _showLoginDialog(BuildContext context, _NavItem item) {
  final isCommunity = item.route == AppRoutes.community;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.login_outlined,
                  color: Colors.blue[600], size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'ต้องเข้าสู่ระบบ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          isCommunity
              ? 'กรุณาเข้าสู่ระบบก่อนเข้าใช้งานชุมชน'
              : 'กรุณาเข้าสู่ระบบก่อนใช้งานแชทบอท',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    'เข้าสู่ระบบ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
}

// ─── Nav Button ───────────────────────────────────────────────────────────────
class _NavButton extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final bool showBadge;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isActive,
    required this.showBadge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Icon with indicator ────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.symmetric(
              horizontal: isActive ? 14 : 10,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? _kActive.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey(isActive),
                    size: 22,
                    color: isActive ? _kActive : _kInactive,
                  ),
                ),
                // Login required badge
                if (showBadge)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE05252),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          // ── Label ────────────────────────────────────────────────────
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            style: TextStyle(
              fontSize: isActive ? 11 : 10,
              fontWeight:
                  isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? _kActive : _kInactive,
            ),
            child: Text(item.label),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Model ───────────────────────────────────────────────────────────
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool requireLogin;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.requireLogin = false,
  });
}