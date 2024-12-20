import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const firebaseOptions = FirebaseOptions(
    apiKey: "AIzaSyDnEWkE9JJkKXUIdlNnsPjmyvBBpHXxpNQ",
    appId: "1:451937564533:android:0022abe90a75ea2237c53c",
    messagingSenderId: "451937564533",
    projectId: "doggy-training-51e3d",
    authDomain: "doggy-training-51e3d.firebaseapp.com",  // หากมี
    storageBucket: "doggy-training-51e3d.firebasestorage.app",
    measurementId: "", // หากมีค่า measurementId ใน Firebase Console ก็สามารถเพิ่มได้
  );

  // เริ่ม Firebase
  await Firebase.initializeApp(options: firebaseOptions);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Firebase Test')),
        body: Center(child: Text('Firebase is connected!')),
      ),
    );
  }
}
