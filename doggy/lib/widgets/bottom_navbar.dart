// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../routes/app_routes.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int)? onTap; // ทำให้ optional

  const BottomNavBar({
    Key? key,
    required this.currentIndex,
    this.onTap, // ไม่บังคับต้องส่งมา
  }) : super(key: key);

  // ฟังก์ชัน navigation ที่ใช้ร่วมกัน
  void _handleNavigation(BuildContext context, int index) {
    print('Debug: BottomNavBar tapped index $index');
    
    switch (index) {
      case 0: // หน้าหลัก
        if (ModalRoute.of(context)?.settings.name != AppRoutes.home) {
          print('Debug: Navigating to home');
          Navigator.pushReplacementNamed(context, AppRoutes.home);
        } else {
          print('Debug: Already on home page');
        }
        break;
      case 1: // คอร์สเรียน
        if (ModalRoute.of(context)?.settings.name != AppRoutes.courses) {
          print('Debug: Navigating to courses');
          Navigator.pushReplacementNamed(context, AppRoutes.courses);
        } else {
          print('Debug: Already on courses page');
        }
        break;
      case 2: // ชุมชน
        if (ModalRoute.of(context)?.settings.name != AppRoutes.community) {
          print('Debug: Navigating to community');
          Navigator.pushReplacementNamed(context, AppRoutes.community);
        } else {
          print('Debug: Already on community page');
        }
        break;
      case 3: // แชทบอท
        if (ModalRoute.of(context)?.settings.name != AppRoutes.chat) {
          print('Debug: Navigating to chat');
          Navigator.pushReplacementNamed(context, AppRoutes.chat);
        } else {
          print('Debug: Already on chat page');
        }
        break;
      default:
        print('Debug: Unknown index $index');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final currentRoute = ModalRoute.of(context)?.settings.name;
    
    // หา currentIndex จาก route ปัจจุบัน หรือใช้ที่ส่งมา
    int displayIndex = currentIndex;
    
    // ตรวจสอบ route ปัจจุบันเพื่อกำหนด active index ให้ถูกต้อง
    switch (currentRoute) {
      case AppRoutes.home:
        displayIndex = 0;
        break;
      case AppRoutes.courses:
        displayIndex = 1;
        break;
      case AppRoutes.community:
        displayIndex = 2;
        break;
      case AppRoutes.chat:
        displayIndex = 3;
        break;
    }
    
    print('Debug: Current route: $currentRoute, Display index: $displayIndex');

    // รายการของ bottom nav
    final List<_NavItem> navItems = [
      _NavItem(
        label: 'หน้าหลัก',
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        route: AppRoutes.home,
      ),
      _NavItem(
        label: 'คอร์สเรียน',
        icon: Icons.school_outlined,
        activeIcon: Icons.school,
        route: AppRoutes.courses,
      ),
      _NavItem(
        label: 'ชุมชน',
        icon: Icons.groups_outlined,
        activeIcon: Icons.groups,
        route: AppRoutes.community,
      ),
      _NavItem(
        label: 'แชทบอท',
        icon: Icons.chat_bubble_outline,
        activeIcon: Icons.chat_bubble,
        route: AppRoutes.chat,
        requireLogin: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD2B48C),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: displayIndex, // ใช้ displayIndex แทน currentIndex
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF8B4513), // สีน้ำตาลเข้มเมื่อ active
        unselectedItemColor: Colors.brown[600],
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedFontSize: 13,
        unselectedFontSize: 11,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
        items: navItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isActive = displayIndex == index; // ใช้ displayIndex แทน currentIndex
          final isChat = item.label == 'แชทบอท';
          final showLoginBadge = isChat && user == null;

          Widget iconWidget;

          if (showLoginBadge) {
            iconWidget = Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? item.activeIcon : item.icon,
                  size: isActive ? 26 : 24,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 14,
                      minHeight: 14,
                    ),
                    child: const Text(
                      '!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          } else {
            iconWidget = AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(isActive ? 4 : 0),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                size: isActive ? 26 : 24,
              ),
            );
          }

          return BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: iconWidget,
            ),
            label: item.label,
          );
        }).toList(),
        onTap: (index) {
          final selectedItem = navItems[index];
          if (selectedItem.requireLogin && user == null) {
            _showLoginRequiredDialog(context);
          } else {
            // ใช้ฟังก์ชัน navigation ภายในตัว widget
            if (onTap != null) {
              onTap!(index); // เรียก custom function ถ้ามี
            } else {
              _handleNavigation(context, index); // ใช้ default navigation
            }
          }
        },
      ),
    );
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 10,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.login_outlined,
                  color: Colors.blue[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'ต้องเข้าสู่ระบบ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'กรุณาเข้าสู่ระบบก่อนใช้งานแชทบอทเพื่อรับคำแนะนำการฝึกสุนัขแบบส่วนตัว',
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
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
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'เข้าสู่ระบบ',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
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

// เก็บข้อมูลแต่ละปุ่มใน BottomNavBar
class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool requireLogin;

  _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    this.requireLogin = false,
  });
}