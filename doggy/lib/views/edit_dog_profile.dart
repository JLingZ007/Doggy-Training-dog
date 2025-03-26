import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class EditDogProfilePage extends StatefulWidget {
  final Map<String, dynamic>? dogData;
  final String? docId;

  EditDogProfilePage({this.dogData, this.docId});

  @override
  _EditDogProfilePageState createState() => _EditDogProfilePageState();
}

class _EditDogProfilePageState extends State<EditDogProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TextEditingController nameController = TextEditingController();
  TextEditingController ageController = TextEditingController();
  TextEditingController imageUrlController = TextEditingController();

  String? selectedGender;
  String? selectedBreed;

  List<String> genders = ['เพศผู้', 'เพศเมีย'];
  List<String> breeds = ['ปอมเมอเรเนียน', 'ชิวาวา', 'โกลเด้น', 'ลาบราดอร์'];

  @override
  void initState() {
    super.initState();
    if (widget.dogData != null) {
      nameController.text = widget.dogData!['name'] ?? '';
      ageController.text = widget.dogData!['age'] ?? '1';
      selectedBreed = breeds.contains(widget.dogData!['breed'])
          ? widget.dogData!['breed']
          : breeds.first;
      imageUrlController.text = widget.dogData!['image'] ?? '';
      selectedGender = genders.contains(widget.dogData!['gender'])
          ? widget.dogData!['gender']
          : genders.first;
    }
  }

  Future<void> _saveProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final dogData = {
      'name': nameController.text,
      'age': ageController.text,
      'gender': selectedGender ?? genders.first,
      'breed': selectedBreed ?? breeds.first,
      'image': imageUrlController.text,
    };

    if (widget.docId != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .doc(widget.docId)
          .update(dogData);
    } else {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .add(dogData);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลสุนัข',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: imageUrlController.text.isNotEmpty
                  ? Image.network(imageUrlController.text,
                      height: 180, fit: BoxFit.cover)
                  : Image.asset('assets/images/dog_profile.png',
                      height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),

            // ช่องกรอกชื่อสุนัข
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อสุนัข',
                filled: true,
                fillColor: Colors.brown[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Dropdown เลือกอายุ
            DropdownButtonFormField<String>(
              value: (ageController.text.isNotEmpty &&
                      List.generate(15, (index) => '${index + 1} ปี')
                          .contains(ageController.text))
                  ? ageController.text
                  : '1 ปี',
              items: List.generate(15, (index) => '${index + 1} ปี')
                  .map((age) => DropdownMenuItem(value: age, child: Text(age)))
                  .toList(),
              onChanged: (value) =>
                  setState(() => ageController.text = value ?? '1 ปี'),
              decoration: InputDecoration(
                labelText: 'อายุ',
                filled: true,
                fillColor: Colors.brown[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Dropdown เลือกเพศ
            DropdownButtonFormField<String>(
              value: selectedGender,
              items: genders
                  .map((gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) => setState(() => selectedGender = value),
              decoration: InputDecoration(
                labelText: 'เพศ',
                filled: true,
                fillColor: Colors.brown[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // Dropdown เลือกสายพันธุ์
            DropdownButtonFormField<String>(
              value: selectedBreed,
              items: breeds
                  .map((breed) =>
                      DropdownMenuItem(value: breed, child: Text(breed)))
                  .toList(),
              onChanged: (value) => setState(() => selectedBreed = value),
              decoration: InputDecoration(
                labelText: 'สายพันธุ์',
                filled: true,
                fillColor: Colors.brown[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),

            // ช่องใส่ลิงก์รูปโปรไฟล์ของสุนัข
            TextField(
              controller: imageUrlController,
              decoration: InputDecoration(
                labelText: 'ลิงก์รูปโปรไฟล์สุนัข',
                filled: true,
                fillColor: Colors.brown[100],
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) => setState(() {}),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // ปุ่มบันทึก
                ElevatedButton(
                  onPressed: _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('บันทึก',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),

                // ปุ่มยกเลิก
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown[300],
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('ยกเลิก',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
