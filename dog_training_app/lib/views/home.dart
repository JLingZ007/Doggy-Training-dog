import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../widgets/slidebar.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/background_widget.dart';
import '../routes/app_routes.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0; 
  int _carouselIndex = 0;

  final List<String> _carouselImages = [
    'assets/images/drip_dog4.jpg',
    'assets/images/drip_dog2.jpg',
    'assets/images/drip_dog3.jpg',
  ];

  void _onNavBarTap(int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        break;
      case 1:
        Navigator.pushReplacementNamed(context, AppRoutes.myCourses);
        break;
      case 2:
        Navigator.pushReplacementNamed(context, AppRoutes.courses);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[200],
        elevation: 0,
        title: const Text(
          '',
          style: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/images/dog_profile.png'),
            ),
          ),
        ],
      ),
      drawer: SlideBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 📌 Banner Section
            Stack(
              children: [
                // รูปภาพหลักของ Banner
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                      image: AssetImage('assets/images/drip_dog4.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Overlay
                Container(
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
                // ข้อความทับบน Banner
                Positioned(
                  bottom: 30,
                  left: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🐶 ยินดีต้อนรับกลับ!',
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'พร้อมฝึกสุนัขของคุณหรือยัง? 🦴',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 📌 ปุ่มเมนู
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuButton(Icons.school, 'คอร์สเรียนของฉัน', AppRoutes.myCourses),
                  const SizedBox(height: 15),
                  _buildMenuButton(Icons.menu_book, 'คอร์สเรียนทั้งหมด', AppRoutes.courses),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 📌 Carousel Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CarouselSlider(
                  items: _carouselImages.map((imagePath) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        image: DecorationImage(
                          image: AssetImage(imagePath),
                          fit: BoxFit.cover, // ✅ รูปภาพเต็มพื้นที่ ไม่มีขอบว่าง
                        ),
                      ),
                    );
                  }).toList(),
                  options: CarouselOptions(
                    height: 200,
                    autoPlay: true,
                    autoPlayInterval: Duration(seconds: 4),
                    enlargeCenterPage: true,
                    viewportFraction: 0.9, // ✅ ให้รูปภาพมีขนาดเต็มพื้นที่
                    onPageChanged: (index, reason) {
                      setState(() {
                        _carouselIndex = index;
                      });
                    },
                  ),
                ),
              ),
            ),

            // 📌 Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _carouselImages.asMap().entries.map((entry) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _carouselIndex == entry.key ? 12 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _carouselIndex == entry.key ? Colors.brown : Colors.brown.withOpacity(0.3),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavBarTap,
      ),
    );
  }

  // ฟังก์ชันสร้างปุ่มแบบ Card
  Widget _buildMenuButton(IconData icon, String title, String routeName) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, routeName);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Colors.brown, Colors.brown],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
