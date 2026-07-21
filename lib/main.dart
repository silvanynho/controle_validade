import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/login.dart';

void main() async {
  // Garante a inicialização dos componentes nativos do Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Tenta inicializar o Firebase sem travar o app se houver erro
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint("Tempo limite esgotado ao inicializar o Firebase.");
      },
    );
  } catch (e) {
    // Captura e exibe o erro no console de depuração se algo falhar
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
        useMaterial3: false, // Mantém a compatibilidade com o primarySwatch
      ),
      home: const TelaLogin(),
    );
  }
}
