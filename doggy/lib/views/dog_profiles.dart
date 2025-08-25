import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import 'add_dog.dart';
import 'edit_dog_profile.dart';

class DogProfilesPage extends StatefulWidget {
  @override
  _DogProfilesPageState createState() => _DogProfilesPageState();
}

class _DogProfilesPageState extends State<DogProfilesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final UserService _userService = UserService();

  // ลบโปรไฟล์สุนัข (ถ้าตัวที่ลบเป็นตัว active ให้เคลียร์ activeDogId)
  Future<void> _deleteDogProfile(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dogs')
        .doc(docId)
        .delete();

    await _userService.clearActiveDogIfDeleted(docId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ลบโปรไฟล์สุนัขแล้ว')),
    );
  }

  // แปลงข้อมูล image เป็น ImageProvider
  ImageProvider _buildImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/images/dog_profile.jpg');
    }
    if (imageData.startsWith('http')) return NetworkImage(imageData);
    // ถ้าเป็น Base64
    try {
      if (imageData.length > 100) {
        return MemoryImage(base64Decode(imageData));
      }
    } catch (_) {}
    return const AssetImage('assets/images/dog_profile.jpg');
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข้อมูลสุนัขของคุณ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFD2B48C),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: (user == null)
            ? const Center(child: Text('กรุณาเข้าสู่ระบบ'))
            : Column(
                children: [
                  // ฟัง activeDogId ตลอดเวลา เพื่อแสดง badge/ปุ่ม
                  StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: _firestore.collection('users').doc(user.uid).snapshots(),
                    builder: (context, userSnap) {
                      final activeDogId =
                          userSnap.data?.data()?['activeDogId'] as String?;

                      return Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _firestore
                              .collection('users')
                              .doc(user.uid)
                              .collection('dogs')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.pets, size: 60, color: Colors.grey),
                                    SizedBox(height: 20),
                                    Text('ยังไม่มีข้อมูลสุนัข',
                                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                                  ],
                                ),
                              );
                            }

                            final dogs = snapshot.data!.docs;

                            return ListView.builder(
                              itemCount: dogs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    dogs[index].data() as Map<String, dynamic>;
                                final dogId = dogs[index].id;

                                final isActive = activeDogId == dogId;

                                return Card(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    leading: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: _buildImage(data['image']),
                                    ),
                                    title: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            data['name'] ?? 'ไม่ระบุ',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (isActive)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFA4D6A7),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'กำลังติดตาม',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 6.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('อายุ: ${data['age'] ?? '-'}',
                                              style: const TextStyle(fontSize: 14)),
                                          Text('สายพันธุ์: ${data['breed'] ?? '-'}',
                                              style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'select') {
                                          await _userService.setActiveDogId(dogId);
                                        } else if (val == 'edit') {
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => EditDogProfilePage(
                                                dogData: data,
                                                docId: dogId,
                                              ),
                                            ),
                                          );
                                        } else if (val == 'delete') {
                                          await _deleteDogProfile(dogId);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (!isActive)
                                          const PopupMenuItem(
                                            value: 'select',
                                            child: ListTile(
                                              leading: Icon(Icons.check_circle),
                                              title: Text('ตั้งเป็นตัวที่ติดตาม'),
                                            ),
                                          ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: ListTile(
                                            leading: Icon(Icons.edit),
                                            title: Text('แก้ไขข้อมูล'),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: ListTile(
                                            leading: Icon(Icons.delete, color: Colors.red),
                                            title: Text('ลบ'),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      // แตะรายการ = ตั้งเป็นตัวที่ติดตามอย่างรวดเร็ว
                                      if (!isActive) {
                                        await _userService.setActiveDogId(dogId);
                                      }
                                    },
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddDogPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown[300],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    child: const Text('เพิ่มสุนัข',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ],
              ),
      ),
    );
  }
}
