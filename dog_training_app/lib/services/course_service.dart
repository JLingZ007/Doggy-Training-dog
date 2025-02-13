import '../models/course.dart';

class CourseService {
  static final CourseService _instance = CourseService._internal();
  factory CourseService() => _instance;

  CourseService._internal();

  final List<Course> _myCourses = [];

  List<Course> get myCourses => _myCourses;

  void addCourse(Course course) {
    if (!_myCourses.any((c) => c.id == course.id)) {
      _myCourses.add(course);
    }
  }

  void markCourseCompleted(String id) {
    final course = _myCourses.firstWhere((c) => c.id == id, orElse: () => Course(id: '', title: '', imageUrl: ''));
    if (course.id.isNotEmpty) {
      course.isCompleted = true;
    }
  }
}
