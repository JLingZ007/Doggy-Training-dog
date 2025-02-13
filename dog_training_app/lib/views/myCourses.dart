import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/course_service.dart';

class MyCoursesPage extends StatefulWidget {
  @override
  _MyCoursesPageState createState() => _MyCoursesPageState();
}

class _MyCoursesPageState extends State<MyCoursesPage> {
  final CourseService courseService = CourseService();

  @override
  Widget build(BuildContext context) {
    final myCourses = courseService.myCourses;

    return Scaffold(
      appBar: AppBar(title: const Text('คอร์สเรียนของฉัน')),
      body: myCourses.isEmpty
          ? const Center(child: Text('ยังไม่มีคอร์สที่เพิ่ม'))
          : ListView.builder(
              itemCount: myCourses.length,
              itemBuilder: (context, index) {
                final course = myCourses[index];

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: Image.network(
                      course.imageUrl,
                      width: 50,
                      height: 50,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset('assets/images/default_image.png', width: 50, height: 50);
                      },
                    ),
                    title: Text(course.title),
                    subtitle: Text(course.isCompleted ? '✔ ฝึกสำเร็จแล้ว' : '📘 กำลังเรียนรู้'),
                    trailing: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          courseService.markCourseCompleted(course.id);
                        });
                      },
                      child: const Text('✔ ทำสำเร็จ'),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
