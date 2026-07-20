import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ControleValidadeApp());
}

class ControleValidadeApp extends StatelessWidget {
  const ControleValidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Validade',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TelaLogin(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final TextEditingController _usuario = TextEditingController();
  final TextEditingController _senha = TextEditingController();

  void _entrar() {
    if (_usuario.text == 'admin' && _senha.text == '1234') {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TelaPrincipal()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário ou senha incorretos!'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.inventory_2_outlined, size: 80, color: Colors.blue),
              const SizedBox(height: 20),
              const Text('Controle de Validade', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _usuario, decoration: const InputDecoration(labelText: 'Usuário', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
              const SizedBox(height: 25),
              ElevatedButton(onPressed: _entrar, child: const Text('Entrar', style: TextStyle(fontSize: 18)))
            ],
          ),
        ),
      ),
    );
  }
}

class Produto {
  final String id;
  final String nome;
  final DateTime validade;
  final int quantidade;
  final double valor;

  Produto({required this.id, required this.nome, required this.validade, required this.quantidade, required this.valor});

  int get diasRestantes => validade.difference(DateTime.now()).inDays;
  bool get vencido => diasRestantes < 0;
  bool get aviso => diasRestantes <= 7 && !vencido;
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final List<Produto> _lista = [];
  double get saldoTotal => _lista.fold(0, (s, p) => s + (p.valor * p.quantidade));

  void _abrirLeitor() => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLeitor(aoLer: (cod) => _abrirCadastro(cod))));
  void _abrirCadastro([String? cod]) => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastro(codigo: cod, aoSalvar: (p) => setState(() => _lista.add(p)))));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estoque de Produtos'), actions: [Text('Saldo: R\$ ${saldoTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)), const SizedBox(width: 15)]),
      floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(onPressed: _abrirLeitor, child: const Icon(Icons.qr_code_scanner), heroTag: 'leitor'),
        const SizedBox(height: 10),
        FloatingActionButton(onPressed: _abrirCadastro, child: const Icon(Icons.add), heroTag: 'cadastro')
      ]),
      body: _lista.isEmpty ? const Center(child: Text('Nenhum produto cadastrado', style: TextStyle(fontSize: 18))) : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _lista.length,
        itemBuilder: (_, i) {
          final p = _lista[i];
          return Card(
            color: p.vencido ? Colors.red[100] : p.aviso ? Colors.orange[100] : Colors.white,
            child: ListTile(
              title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Código: ${p.id}\nValidade: ${DateFormat('dd/MM/yyyy').format(p.validade)} | Dias: ${p.diasRestantes}\nQtd: ${p.quantidade} | Valor: R\$ ${p.valor.toStringAsFixed(2)}'),
              trailing: p.vencido ? const Text('VENCIDO', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)) : p.aviso ? const Text('ALERTA', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)) : null,
            ),
          );
        },
      ),
    );
  }
}

class TelaLeitor extends StatelessWidget {
  final Function(String) aoLer;
  const TelaLeitor({super.key, required this.aoLer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ler Código')),
      body: MobileScanner(onDetect: (res) {
        if (res.barcodes.isNotEmpty) {
          final cod = res.barcodes.first.rawValue ?? '';
          Navigator.pop(context);
          aoLer(cod);
        }
      }),
    );
  }
}

class TelaCadastro extends StatefulWidget {
  final String? codigo;
  final Function(Produto) aoSalvar;
  const TelaCadastro({super.key, this.codigo, required this.aoSalvar});

  @override
  State<TelaCadastro> createState() => _TelaCadastroState();
}

class _TelaCadastroState extends State<TelaCadastro> {
  late final TextEditingController _cod;
  final _nome = TextEditingController();
  final _qtd = TextEditingController();
  final _valor = TextEditingController();
  DateTime? _dataValidade;

  @override
  void initState() {
    super.initState();
    _cod = TextEditingController(text: widget.codigo ?? '');
  }

  void _salvar() {
    if (_cod.text.isEmpty || _nome.text.isEmpty || _qtd.text.isEmpty || _valor.text.isEmpty || _dataValidade == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos!')));
      return;
    }
    final prod = Produto(
      id: _cod.text,
      nome: _nome.text,
      validade: _dataValidade!,
      quantidade: int.parse(_qtd.text),
      valor: double.parse(_valor.text.replaceAll(',', '.'))
    );
    widget.aoSalvar(prod);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Produto')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _cod, decoration: const InputDecoration(labelText: 'Código / Código de Barras', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _qtd, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _valor, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Valor Unitário (R\$)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            ListTile(
              title: Text(_dataValidade == null ? 'Escolher Data de Validade' : DateFormat('dd/MM/yyyy').format(_dataValidade!)),
              trailing: const Icon(Icons.calendar_today),
              shape: Border.all(color: Colors.grey),
              onTap: () async {
                final data = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime(2100));
                if (data != null) setState(() => _dataValidade = data);
              },
            ),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: _salvar, child: const Text('Salvar Produto', style: TextStyle(fontSize: 18)))
          ],
        ),
      ),
    );
  }
}
