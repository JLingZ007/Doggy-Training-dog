import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/slidebar.dart'; // สมมติว่า path นี้ถูกต้อง
import '../routes/app_routes.dart'; // สมมติว่า path นี้ถูกต้อง

// แปลงเป็น StatefulWidget เพื่อดึงข้อมูลและอัปเดต title
class TrainingProgramsPage extends StatefulWidget {
  final String categoryId;

  const TrainingProgramsPage({super.key, required this.categoryId});

  @override
  State<TrainingProgramsPage> createState() => _TrainingProgramsPageState();
}

class _TrainingProgramsPageState extends State<TrainingProgramsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _categoryName = 'กำลังโหลด...';
  late Future<List<Map<String, dynamic>>> _programsFuture;

  @override
  void initState() {
    super.initState();
    _programsFuture = _fetchData();
  }

  // ดึงทั้งชื่อหมวดหมู่ (เพื่ออัปเดต state) และรายการโปรแกรม
  Future<List<Map<String, dynamic>>> _fetchData() async {
    try {
      final categoryDoc = await _firestore
          .collection('training_categories')
          .doc(widget.categoryId)
          .get();

      if (mounted) {
        setState(() {
          _categoryName = categoryDoc.data()?['name'] ?? 'ไม่พบชื่อ';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryName = 'ข้อผิดพลาด';
        });
      }
    }

    final snapshot = await _firestore
        .collection('training_categories')
        .doc(widget.categoryId)
        .collection('programs')
        .get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  @override
  Widget build(BuildContext context) {
    // สี tan ตามที่ต้องการ
    const Color tan = Color(0xFFD2B48C);

    return Scaffold(
      appBar: AppBar(
        // ** ปรับแก้ AppBar ตามที่ร้องขอ **
        title: Text('บทเรียน: $_categoryName',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.w700)),
        backgroundColor: tan,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      drawer: const SlideBar(), // สมมติว่า SlideBar เป็น widget ที่ถูกต้อง
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _programsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          final programs = snapshot.data ?? [];
          if (programs.isEmpty) {
            return const Center(child: Text('ไม่มีบทเรียนในหมวดหมู่นี้'));
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final maxW = constraints.maxWidth;
              // จำนวนคอลัมน์ที่ปรับตามขนาดหน้าจอ
              final crossAxisCount = (maxW >= 900)
                  ? 4
                  : (maxW >= 600)
                      ? 3
                      : 2;

              return GridView.builder(
                padding: const EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  // ** ปรับแก้: เพิ่มค่าเพื่อให้การ์ดสั้นลง (ดูเล็กลง) **
                  childAspectRatio: 0.9,
                  // เพิ่มระยะห่างระหว่างการ์ด
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final program = programs[index];
                  return _ProgramCard(
                    name: program['name'] ?? 'ไม่มีชื่อโปรแกรม',
                    imageUrl: program['image'] ?? '',
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.trainingDetails,
                        arguments: {
                          'documentId': program['id'],
                          'categoryId': widget.categoryId,
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// การ์ดโปรแกรมที่ออกแบบใหม่ให้ดูทันสมัยขึ้น
class _ProgramCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _ProgramCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ใช้ Expanded เพื่อให้รูปภาพขยายเต็มพื้นที่ที่เหลือ
            // ทำให้รูปภาพทุกใบมีขนาดเท่ากันและสมส่วนกับการ์ด
            Expanded(
              child: (imageUrl.isNotEmpty)
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (_, __, ___) => _errorBox(),
                    )
                  : _errorBox(),
            ),
            // ส่วนข้อความที่ออกแบบใหม่
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
              child: Text(
                name,
                textAlign: TextAlign.left, // จัดข้อความชิดซ้าย
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder สำหรับรูปภาพที่โหลดไม่ได้หรือไม่พบ
  Widget _errorBox() => Container(
        color: Colors.grey.shade200,
        alignment: Alignment.center,
        child: Icon(Icons.pets_rounded, size: 40, color: Colors.grey.shade400),
      );
}

