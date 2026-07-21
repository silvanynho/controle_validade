import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _senhaVisivel = false; // Controla mostrar/esconder
  bool _modoCadastro = false;

  Future<void> _fazerAcao() async {
    try {
      if (_modoCadastro) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _senha.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _senha.text.trim(),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_modoCadastro ? 'Cadastro feito!' : 'Bem-vindo!'),
            backgroundColor: Colors.green,
          ),
        );
        // Coloque aqui a navegação para a tela inicial
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'Erro ao acessar'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_modoCadastro ? 'Cadastro' : 'Login'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            // CAMPO COM BOTÃO DE VER SENHA
            TextField(
              controller: _senha,
              obscureText: !_senhaVisivel, // Esconde ou mostra
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _senhaVisivel ? Icons.visibility_off : Icons.visibility,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    setState(() {
                      _senhaVisivel = !_senhaVisivel;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _fazerAcao,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(14),
                  backgroundColor: Colors.green,
                ),
                child: Text(
                  _modoCadastro ? 'Cadastrar' : 'Entrar',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _modoCadastro = !_modoCadastro;
                });
              },
              child: Text(
                _modoCadastro
                    ? 'Já tem conta? Entrar'
                    : 'Não tem conta? Cadastre-se',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
