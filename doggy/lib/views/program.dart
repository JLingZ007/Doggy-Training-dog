import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/slidebar.dart';
import '../routes/app_routes.dart';

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

  static const Color tan = Color(0xFFD2B48C);

  @override
  void initState() {
    super.initState();
    _programsFuture = _fetchData();
  }

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

    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data()})
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE6),
      drawer: const SlideBar(),
      appBar: AppBar(
        title: Text(
          'บทเรียน: $_categoryName',
          style: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: tan,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
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
              int crossAxisCount = 2;

              if (constraints.maxWidth > 900) {
                crossAxisCount = 4;
              } else if (constraints.maxWidth > 600) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  childAspectRatio: 0.82,
                ),
                itemCount: programs.length,
                itemBuilder: (context, index) {
                  final program = programs[index];

                  return _ProgramCard(
                    id: program['id'],
                    name: program['name'] ?? '',
                    imageUrl: program['image'] ?? '',
                    categoryId: widget.categoryId,
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

class _ProgramCard extends StatefulWidget {
  final String id;
  final String name;
  final String imageUrl;
  final String categoryId;

  const _ProgramCard({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.categoryId,
  });

  @override
  State<_ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<_ProgramCard> {
  double scale = 1;

  void _tapDown(TapDownDetails d) {
    setState(() => scale = 0.95);
  }

  void _tapUp(TapUpDetails d) {
    setState(() => scale = 1);
  }

  void _tapCancel() {
    setState(() => scale = 1);
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B3F1D);

    return GestureDetector(
      onTapDown: _tapDown,
      onTapUp: _tapUp,
      onTapCancel: _tapCancel,
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.trainingDetails,
          arguments: {
            'documentId': widget.id,
            'categoryId': widget.categoryId,
          },
        );
      },
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// IMAGE
              Hero(
                tag: widget.id,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        widget.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _errorBox(),
                              )
                            : _errorBox(),

                        /// gradient overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.35),
                                  Colors.transparent
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              /// TEXT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                  child: Text(
                    widget.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                      color: brown,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      color: const Color(0xFFEDE7E0),
      child: const Center(
        child: Icon(Icons.pets, size: 40, color: Colors.grey),
      ),
    );
  }
}