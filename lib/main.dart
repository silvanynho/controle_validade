import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AlzaSyCjVdtlcIByb9H6DJTOkjSw-17CTSR6hwO",
      appId: "1677339036980:android:dfa4957b23b406c16c7961",
      messagingSenderId: "677339036980",
      projectId: "nutri-control-2a34d",
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Nutri Control",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TelaLogin(),
    );
  }
}
