class Dog {
  final String id;
  final String name;
  final String breed;
  final int age;

  Dog({
    required this.id,
    required this.name,
    required this.breed,
    required this.age,
  });

  // Factory สำหรับแปลงข้อมูลจาก Firebase
  factory Dog.fromJson(Map<String, dynamic> json) {
    return Dog(
      id: json['id'],
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
    );
  }

  // Method สำหรับแปลงข้อมูลเป็น JSON เพื่อบันทึกใน Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'breed': breed,
      'age': age,
    };
  }
}
