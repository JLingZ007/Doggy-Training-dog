class Course {
  final String id;
  final String title;
  final String imageUrl;
  bool isCompleted;

  Course({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.isCompleted = false,
  });
}
