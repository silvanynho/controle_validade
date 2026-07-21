import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/login.dart';

void main() async {
  // Garante a inicialização dos bindings nativos do Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Inicializa o Firebase. Se falhar, o bloco catch captura o erro
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Erro ao inicializar o Firebase: $e");
  }

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
        useMaterial3: false,
      ),
      home: const TelaLogin(),
    );
  }
}
