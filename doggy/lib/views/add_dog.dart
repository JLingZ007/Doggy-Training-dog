import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddDogPage extends StatefulWidget {
  @override
  _AddDogPageState createState() => _AddDogPageState();
}

class _AddDogPageState extends State<AddDogPage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedGender;
  String? selectedBreed;
  File? selectedImageFile;

  final List<String> genders = ['เพศผู้', 'เพศเมีย'];
  final List<String> breeds = [
    'ปอมเมอเรเนียน',
    'ชิวาวา',
    'โกลเด้น',
    'ลาบราดอร์'
  ];

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveDog() async {
    if (!_formKey.currentState!.validate()) return;
    final user = _auth.currentUser;
    if (user == null) return;

    String? base64Image;
    if (selectedImageFile != null) {
      final bytes = await selectedImageFile!.readAsBytes();
      base64Image = base64Encode(bytes);
    }

    final dogData = {
      'name': nameController.text.trim(),
      'age': ageController.text.trim(),
      'gender': selectedGender ?? '',
      'breed': selectedBreed ?? '',
      'image': base64Image ?? '',
    };

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('dogs')
        .add(dogData);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("สำเร็จ"),
        content: const Text("บันทึกข้อมูลสุนัขเรียบร้อยแล้ว"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ปิด Alert
              Navigator.pop(context); // กลับหน้าเดิม
            },
            child: const Text("ตกลง"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidget = selectedImageFile != null
        ? Image.file(selectedImageFile!, height: 180, fit: BoxFit.cover)
        : Image.asset('assets/images/dog_profile.jpg',
            height: 180, fit: BoxFit.cover);

    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มข้อมูลสุนัข'),
        backgroundColor: Colors.brown,
      ),
      backgroundColor: Colors.brown[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('ชื่อสุนัข'),
                validator: (value) =>
                    value!.isEmpty ? 'กรุณากรอกชื่อสุนัข' : null,
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: ageController.text.isNotEmpty ? ageController.text : '1 ปี',
                items: List.generate(15, (i) => '${i + 1} ปี')
                    .map((age) => DropdownMenuItem(value: age, child: Text(age)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => ageController.text = value!),
                decoration: _inputDecoration('อายุ'),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedGender,
                items: genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => selectedGender = value),
                decoration: _inputDecoration('เพศ'),
              ),
              const SizedBox(height: 10),

              DropdownButtonFormField<String>(
                value: selectedBreed,
                items: breeds
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (value) => setState(() => selectedBreed = value),
                decoration: _inputDecoration('สายพันธุ์'),
              ),
              const SizedBox(height: 10),

              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text("อัปโหลดรูปภาพ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[300],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(height: 25),

              ElevatedButton(
                onPressed: _saveDog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown,
                  minimumSize: const Size(400, 50),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.brown[100],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
