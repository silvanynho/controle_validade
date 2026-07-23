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
  bool _senhaVisivel = false;
  bool _modoCadastro = false;
  bool _carregando = false;

  Future<void> _acao() async {
    setState(() => _carregando = true);
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
          const SnackBar(content: Text('Sucesso! Entrando...'), backgroundColor: Colors.green)
        );
        // Coloque aqui a navegação para sua tela inicial/home
      }
    } on FirebaseAuthException catch (e) {
      String mensagem;
      switch (e.code) {
        case 'invalid-email': mensagem = 'E-mail inválido'; break;
        case 'user-not-found': mensagem = 'Usuário não encontrado'; break;
        case 'wrong-password': mensagem = 'Senha incorreta'; break;
        case 'email-already-in-use': mensagem = 'E-mail já cadastrado'; break;
        case 'operation-not-allowed': mensagem = 'Login desativado no Firebase'; break;
        case 'weak-password': mensagem = 'Senha muito fraca (mínimo 6 caracteres)'; break;
        case 'network-request-failed': mensagem = 'Sem conexão com a internet'; break;
        default: mensagem = 'Erro: ${e.code}';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensagem), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Falha: $e'), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_modoCadastro ? 'Cadastro' : 'Login'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _senha,
              obscureText: !_senhaVisivel,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_senhaVisivel ? Icons.visibility_off : Icons.visibility, color: Colors.green),
                  onPressed: () => setState(() => _senhaVisivel = !_senhaVisivel),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _carregando ? null : _acao,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14), backgroundColor: Colors.green),
                child: _carregando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(_modoCadastro ? 'Cadastrar' : 'Entrar', style: const TextStyle(fontSize: 18)),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _modoCadastro = !_modoCadastro),
              child: Text(_modoCadastro ? 'Já tem conta? Entrar' : 'Não tem conta? Cadastre-se'),
            ),
          ],
        ),
      ),
    );
  }
}
