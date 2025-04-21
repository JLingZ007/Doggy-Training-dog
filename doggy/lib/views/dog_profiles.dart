import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_dog.dart';
import 'edit_dog_profile.dart';

class DogProfilesPage extends StatefulWidget {
  @override
  _DogProfilesPageState createState() => _DogProfilesPageState();
}

class _DogProfilesPageState extends State<DogProfilesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ลบโปรไฟล์สุนัข
  Future<void> _deleteDogProfile(String docId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dogs')
        .doc(docId)
        .delete();
  }

  // แปลงข้อมูล image เป็น ImageProvider
  ImageProvider _buildImage(String? imageData) {
    if (imageData == null || imageData.isEmpty) {
      return const AssetImage('assets/images/dog_profile.jpg');
    }

    // ถ้าเป็น Base64
    if (imageData.length > 100) {
      try {
        return MemoryImage(base64Decode(imageData));
      } catch (e) {
        return const AssetImage('assets/images/dog_profile.jpg');
      }
    }

    // ถ้าเป็น URL
    if (imageData.startsWith('http')) {
      return NetworkImage(imageData);
    }

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
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .doc(user?.uid)
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
                        children: [
                          Icon(Icons.pets, size: 60, color: Colors.grey),
                          const SizedBox(height: 20),
                          const Text(
                            'ยังไม่มีข้อมูลสุนัข',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  final dogs = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: dogs.length,
                    itemBuilder: (context, index) {
                      final dog = dogs[index].data() as Map<String, dynamic>;
                      final docId = dogs[index].id;

                      return Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: CircleAvatar(
                            radius: 30,
                            backgroundImage: _buildImage(dog['image']),
                          ),
                          title: Text(dog['name'],
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('อายุ: ${dog['age']}',
                                  style: const TextStyle(fontSize: 14)),
                              Text('สายพันธุ์: ${dog['breed']}',
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.brown),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditDogProfilePage(
                                          dogData: dog, docId: docId),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteDogProfile(docId);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
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
