import 'package:flutter/material.dart';

class SlideBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.brown[50],
        child: Column(
          children: [
            // ส่วนหัว (รูปภาพ + ข้อมูล)
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.brown[100],
              ),
              currentAccountPicture: ClipOval(
                child: Image.asset(
                  'assets/images/dog_profile.png', // ใส่ path ของรูปภาพ
                  fit: BoxFit.cover,
                ),
              ),
              accountName: Text(
                'ชื่อสุนัข: Buddy',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(
                'พันธุ์: Pomeranian',
                style: TextStyle(fontSize: 16),
              ),
            ),

            // เมนูต่าง ๆ
            Expanded(
              child: ListView(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home,
                    title: 'หน้าหลัก',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person,
                    title: 'โปรไฟล์',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.group,
                    title: 'ชุมชน',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.book,
                    title: 'คอร์สของฉัน',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.menu_book,
                    title: 'คอร์สทั้งหมด',
                    onTap: () {},
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.pets,
                    title: 'นกหวีดและคลิกเกอร์',
                    onTap: () {},
                  ),
                ],
              ),
            ),

            // การตั้งค่า และ ออกจากระบบ
            Divider(color: Colors.grey),
            _buildDrawerItem(
              context,
              icon: Icons.settings,
              title: 'การตั้งค่า',
              onTap: () {},
            ),
            _buildDrawerItem(
              context,
              icon: Icons.power_settings_new,
              title: 'ออกจากระบบ',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  // ฟังก์ชันสำหรับสร้างเมนูใน Drawer
  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown),
      title: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      onTap: onTap,
    );
  }
}
