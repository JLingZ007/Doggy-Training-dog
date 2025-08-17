import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditDogProfilePage extends StatefulWidget {
  final Map<String, dynamic>? dogData;
  final String? docId;

  EditDogProfilePage({this.dogData, this.docId});

  @override
  _EditDogProfilePageState createState() => _EditDogProfilePageState();
}

class _EditDogProfilePageState extends State<EditDogProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  String? selectedGender;
  String? selectedBreed;
  File? selectedImageFile;
  String? base64Image;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  final List<String> genders = ['เพศผู้', 'เพศเมีย'];
  final List<String> breeds = [
    'ปอมเมอเรเนียน',
    'ชิวาวา',
    'โกลเด้น',
    'ลาบราดอร์'
  ];

  @override
  void initState() {
    super.initState();
    final dog = widget.dogData;
    if (dog != null) {
      nameController.text = dog['name'] ?? '';
      ageController.text = dog['age'] ?? '1 ปี';
      selectedGender = genders.contains(dog['gender']) ? dog['gender'] : null;
      selectedBreed = breeds.contains(dog['breed']) ? dog['breed'] : null;

      final imageData = dog['image'];
      if (imageData != null && imageData.isNotEmpty) {
        base64Image = imageData;
      }
    }
  }

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

    String? imageToSave = base64Image;
    if (selectedImageFile != null) {
      final bytes = await selectedImageFile!.readAsBytes();
      imageToSave = base64Encode(bytes);
    }

    final dogData = {
      'name': nameController.text.trim(),
      'age': ageController.text.trim(),
      'gender': selectedGender ?? '',
      'breed': selectedBreed ?? '',
      'image': imageToSave ?? '',
    };

    if (widget.docId != null) {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('dogs')
          .doc(widget.docId)
          .update(dogData);
    }

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขข้อมูลสุนัข'),
        backgroundColor: const Color(0xFFD2B48C), // ใช้โทนเดียวกับ Login/Register
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFD2B48C), // พื้นหลัง
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // พรีวิวรูปภาพ
              if (selectedImageFile != null)
                Image.file(selectedImageFile!, height: 180, fit: BoxFit.cover)
              else if (base64Image != null && base64Image!.isNotEmpty)
                Image.memory(base64Decode(base64Image!),
                    height: 180, fit: BoxFit.cover)
              else
                Image.asset('assets/images/dog_profile.jpg',
                    height: 180, fit: BoxFit.cover),

              const SizedBox(height: 15),

              // ชื่อสุนัข
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('ชื่อสุนัข'),
                validator: (value) =>
                    value!.isEmpty ? 'กรุณากรอกชื่อสุนัข' : null,
              ),
              const SizedBox(height: 12),

              // อายุ
              DropdownButtonFormField<String>(
                value: List.generate(15, (i) => '${i + 1} ปี')
                        .contains(ageController.text)
                    ? ageController.text
                    : '1 ปี',
                items: List.generate(15, (i) => '${i + 1} ปี')
                    .map((age) =>
                        DropdownMenuItem(value: age, child: Text(age)))
                    .toList(),
                onChanged: (value) =>
                    setState(() => ageController.text = value!),
                decoration: _inputDecoration('อายุ'),
              ),
              const SizedBox(height: 12),

              // เพศ
              DropdownButtonFormField<String>(
                value: genders.contains(selectedGender) ? selectedGender : null,
                items: genders
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (value) => setState(() => selectedGender = value),
                decoration: _inputDecoration('เพศ'),
              ),
              const SizedBox(height: 12),

              // สายพันธุ์
              DropdownButtonFormField<String>(
                value: breeds.contains(selectedBreed) ? selectedBreed : null,
                items: breeds
                    .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                    .toList(),
                onChanged: (value) => setState(() => selectedBreed = value),
                decoration: _inputDecoration('สายพันธุ์'),
              ),
              const SizedBox(height: 15),

              // ปุ่มอัปโหลดรูปภาพ
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text("อัปโหลดรูปภาพ"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87),
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // ปุ่มบันทึก
              ElevatedButton(
                onPressed: _saveDog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  side: const BorderSide(color: Colors.black87),
                  minimumSize: const Size(400, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'บันทึกข้อมูล',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.black87),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Colors.black, width: 2),
      ),
    );
  }
}
