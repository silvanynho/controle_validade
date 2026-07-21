import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/login.dart';

// ESSA PARTE É OBRIGATÓRIA E ESTAVA FALTANDO!
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutri Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const TelaLogin(),
    );
  }
}
