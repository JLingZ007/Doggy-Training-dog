class TrainingProgram {
  final String id;
  final String name;
  final String description;
  final String difficulty;
  final int duration;
  final List<String> steps;

  TrainingProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.duration,
    required this.steps,
  });

  // Factory สำหรับแปลงข้อมูลจาก Firebase
  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    return TrainingProgram(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      difficulty: json['difficulty'],
      duration: json['duration'],
      steps: List<String>.from(json['steps']),
    );
  }

  // Method สำหรับแปลงข้อมูลเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'duration': duration,
      'steps': steps,
    };
  }
}
