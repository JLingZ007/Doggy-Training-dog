import 'package:flutter/material.dart';
import 'menu_page.dart';

void main() {
  runApp(const DogTrainingApp());
}

class DogTrainingApp extends StatelessWidget {
  const DogTrainingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dog Training App',
      theme: ThemeData(primarySwatch: Colors.brown),
      home: const HomePage(),
    );
  }
}
