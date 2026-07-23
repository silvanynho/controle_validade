import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'telas/login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const IniciarApp());
}

class IniciarApp extends StatefulWidget {
  const IniciarApp({super.key});

  @override
  State<IniciarApp> createState() => _IniciarAppState();
}

class _IniciarAppState extends State<IniciarApp> {
  bool _pronto = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciarFirebase();
  }

  Future<void> _iniciarFirebase() async {
    try {
      await Firebase.initializeApp();
      setState(() => _pronto = true);
    } catch (e) {
      setState(() {
        _erro = e.toString();
        _pronto = true; // Mesmo com erro, mostra a tela para ver mensagem
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutri Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: _pronto 
        ? (_erro != null 
            ? TelaErro(mensagem: _erro!) 
            : const TelaLogin())
        : const TelaCarregamento(),
    );
  }
}

// Tela de carregamento com logo
class TelaCarregamento extends StatelessWidget {
  const TelaCarregamento({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 80, color: Colors.green),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}

// Se der erro, mostra o que aconteceu
class TelaErro extends StatelessWidget {
  final String mensagem;
  const TelaErro({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro de Conexão'), backgroundColor: Colors.red),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 20),
            Text('Não foi possível conectar ao Firebase:\n$mensagem', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaLogin())),
              child: const Text('Continuar mesmo assim'),
            )
          ],
        ),
      ),
    );
  }
}
