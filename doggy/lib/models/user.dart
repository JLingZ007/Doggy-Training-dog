class User {
  final String id; // User ID
  final String name; // ชื่อผู้ใช้
  final String email; // อีเมล
  final String? password; // รหัสผ่าน (เก็บในฝั่งแอปเท่านั้น ไม่เก็บในฐานข้อมูล)
  final String? profilePicture; // รูปโปรไฟล์

  User({
    required this.id,
    required this.name,
    required this.email,
    this.password,
    this.profilePicture,
  });

  // Factory สำหรับแปลงข้อมูลจาก JSON (Firestore)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profilePicture'],
    );
  }

  // Method สำหรับแปลงข้อมูลเป็น JSON (Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
    };
  }
}

