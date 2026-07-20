import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const ControleValidadeApp());
}

class ControleValidadeApp extends StatelessWidget {
  const ControleValidadeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle de Estoque',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TelaInicial(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TelaInicial extends StatelessWidget {
  const TelaInicial({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.hasData ? const TelaPrincipal() : const TelaLogin();
      },
    );
  }
}

class TelaLogin extends StatefulWidget {
  const TelaLogin({super.key});

  @override
  State<TelaLogin> createState() => _TelaLoginState();
}

class _TelaLoginState extends State<TelaLogin> {
  final _usuario = TextEditingController();
  final _senha = TextEditingController();
  final _auth = FirebaseAuth.instance;

  Future<void> _entrar() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _usuario.text.trim(),
        password: _senha.text.trim(),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString().split(']').last}'))
        );
      }
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
              const Text('Controle de Estoque', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(controller: _usuario, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
              const SizedBox(height: 15),
              TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha', border: OutlineInputBorder())),
              const SizedBox(height: 25),
              ElevatedButton(onPressed: _entrar, child: const Text('Entrar', style: TextStyle(fontSize: 18))),
              TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaCadastroUsuario())), child: const Text('Cadastrar novo usuário'))
            ],
          ),
        ),
      ),
    );
  }
}

class TelaCadastroUsuario extends StatefulWidget {
  const TelaCadastroUsuario({super.key});

  @override
  State<TelaCadastroUsuario> createState() => _TelaCadastroUsuarioState();
}

class _TelaCadastroUsuarioState extends State<TelaCadastroUsuario> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _nome = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> _cadastrar() async {
    try {
      final user = await _auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text.trim(),
      );
      await _db.collection('usuarios').doc(user.user!.uid).set({
        'nome': _nome.text.trim(),
        'email': _email.text.trim(),
        'whatsapp': '',
        'alerta_email': false,
        'alerta_whatsapp': false,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar Usuário')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome Completo', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Senha (mínimo 6 caracteres)', border: OutlineInputBorder())),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: _cadastrar, child: const Text('Cadastrar'))
          ],
        ),
      ),
    );
  }
}

class Produto {
  final String id;
  final String codigo;
  final String nome;
  final String marca;
  final String lote;
  final String fornecedor;
  final DateTime validade;
  final int quantidade;

  Produto({
    required this.id,
    required this.codigo,
    required this.nome,
    required this.marca,
    required this.lote,
    required this.fornecedor,
    required this.validade,
    required this.quantidade,
  });

  int get diasRestantes => validade.difference(DateTime.now()).inDays;
  bool get vencido => diasRestantes < 0;
  bool get aviso => diasRestantes <= 7 && !vencido;

  factory Produto.fromMap(String id, Map map) {
    return Produto(
      id: id,
      codigo: map['codigo'] ?? '',
      nome: map['nome'] ?? '',
      marca: map['marca'] ?? '',
      lote: map['lote'] ?? '',
      fornecedor: map['fornecedor'] ?? '',
      validade: (map['validade'] as Timestamp).toDate(),
      quantidade: map['quantidade'] ?? 0,
    );
  }

  Map<String,dynamic> toMap() {
    return {
      'codigo': codigo,
      'nome': nome,
      'marca': marca,
      'lote': lote,
      'fornecedor': fornecedor,
      'validade': validade,
      'quantidade': quantidade,
    };
  }
}

class TelaPrincipal extends StatefulWidget {
  const TelaPrincipal({super.key});

  @override
  State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de Estoque'),
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'marcas', child: Text('Gerenciar Marcas')),
              const PopupMenuItem(value: 'fornecedores', child: Text('Gerenciar Fornecedores')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'config', child: Text('Configurações')),
              const PopupMenuItem(value: 'sair', child: Text('Sair', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (v) {
              if (v == 'marcas') Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaMarcas()));
              if (v == 'fornecedores') Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaFornecedores()));
              if (v == 'config') Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaConfiguracoes()));
              if (v == 'sair') _auth.signOut();
            },
          ),
        ],
      ),
      floatingActionButton: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        FloatingActionButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TelaLeitor(aoLer: (cod) => _abrirCadastro(cod)))), child: const Icon(Icons.qr_code_scanner), heroTag: 'leitor'),
        const SizedBox(height: 10),
        FloatingActionButton(onPressed: () => _abrirCadastro(), child: const Icon(Icons.add), heroTag: 'cadastro'),
      ]),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('produtos').orderBy('validade').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Nenhum produto cadastrado', style: TextStyle(fontSize: 18)));
          final lista = snapshot.data!.docs.map((d) => Produto.fromMap(d.id, d.data() as Map)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: lista.length,
            itemBuilder: (_, i) {
              final p = lista[i];
              return Card(
                color: p.vencido ? Colors.red[100] : p.aviso ? Colors.orange[100] : Colors.white,
                child: ListTile(
                  title: Text(p.nome, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Código: ${p.codigo}\nMarca: ${p.marca} | Lote: ${p.lote}\nFornecedor: ${p.fornecedor}\nValidade: ${DateFormat('dd/MM/yyyy').format(p.validade)} | Dias restantes: ${p.diasRestantes}\nQuantidade: ${p.quantidade}'),
                  trailing: PopupMenuButton(
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'editar', child: Text('Editar')),
                      const PopupMenuItem(value: 'excluir', child: Text('Excluir Produto', style: TextStyle(color: Colors.red))),
                    ],
                    onSelected: (v) {
                      if (v == 'editar') _abrirCadastro(p.codigo, p);
                      if (v == 'excluir') _excluirProduto(p.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _abrirCadastro([String? cod, Produto? prod]) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => TelaCadastroProduto(codigo: cod, produto: prod)));
  }

  Future<void> _excluirProduto(String id) async {
    await _db.collection('produtos').doc(id).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto excluído!')));
  }
}

class TelaMarcas extends StatefulWidget {
  const TelaMarcas({super.key});

  @override
  State<TelaMarcas> createState() => _TelaMarcasState();
}

class _TelaMarcasState extends State<TelaMarcas> {
  final _db = FirebaseFirestore.instance;
  final _nome = TextEditingController();

  Future<void> _cadastrar() async {
    if (_nome.text.trim().isEmpty) return;
    await _db.collection('marcas').add({'nome': _nome.text.trim()});
    _nome.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca cadastrada!')));
  }

  Future<bool> _estaEmUso(String nome) async {
    final res = await _db.collection('produtos').where('marca', isEqualTo: nome).limit(1).get();
    return res.docs.isNotEmpty;
  }

  Future<void> _excluir(String id, String nome) async {
    if (await _estaEmUso(nome)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não pode excluir: há produtos usando essa marca!')));
      return;
    }
    await _db.collection('marcas').doc(id).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Marca excluída!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Marcas')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome da Marca', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _cadastrar, child: const Text('Adicionar'))
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('marcas').orderBy('nome').snapshots(),
              builder: (context, s) {
                if (!s.hasData) return const SizedBox();
                return ListView.builder(
                  itemCount: s.data!.docs.length,
                  itemBuilder: (_,i) {
                    final d = s.data!.docs[i];
                    return ListTile(
                      title: Text(d['nome']),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluir(d.id, d['nome'])),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TelaFornecedores extends StatefulWidget {
  const TelaFornecedores({super.key});

  @override
  State<TelaFornecedores> createState() => _TelaFornecedoresState();
}

class _TelaFornecedoresState extends State<TelaFornecedores> {
  final _db = FirebaseFirestore.instance;
  final _nome = TextEditingController();

  Future<void> _cadastrar() async {
    if (_nome.text.trim().isEmpty) return;
    await _db.collection('fornecedores').add({'nome': _nome.text.trim()});
    _nome.clear();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor cadastrado!')));
  }

  Future<bool> _estaEmUso(String nome) async {
    final res = await _db.collection('produtos').where('fornecedor', isEqualTo: nome).limit(1).get();
    return res.docs.isNotEmpty;
  }

  Future<void> _excluir(String id, String nome) async {
    if (await _estaEmUso(nome)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não pode excluir: há produtos usando esse fornecedor!')));
      return;
    }
    await _db.collection('fornecedores').doc(id).delete();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fornecedor excluído!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gerenciar Fornecedores')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do Fornecedor', border: OutlineInputBorder()))),
                const SizedBox(width: 10),
                ElevatedButton(onPressed: _cadastrar, child: const Text('Adicionar'))
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('fornecedores').orderBy('nome').snapshots(),
              builder: (context, s) {
                if (!s.hasData) return const SizedBox();
                return ListView.builder(
                  itemCount: s.data!.docs.length,
                  itemBuilder: (_,i) {
                    final d = s.data!.docs[i];
                    return ListTile(
                      title: Text(d['nome']),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _excluir(d.id, d['nome'])),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

class TelaCadastroProduto extends StatefulWidget {
  final String? codigo;
  final Produto? produto;
  const TelaCadastroProduto({super.key, this.codigo, this.produto});

  @override
  State<TelaCadastroProduto> createState() => _TelaCadastroProdutoState();
}

class _TelaCadastroProdutoState extends State<TelaCadastroProduto> {
  late final TextEditingController _cod;
  final _nome = TextEditingController();
  final _lote = TextEditingController();
  final _qtd = TextEditingController();
  DateTime? _dataValidade;
  final _db = FirebaseFirestore.instance;
  String? marcaSelecionada;
  String? fornecedorSelecionado;
  List<DropdownMenuItem> listaMarcas = [];
  List<DropdownMenuItem> listaFornecedores = [];

  @override
  void initState() {
    super.initState();
    _cod = TextEditingController(text: widget.codigo ?? widget.produto?.codigo ?? '');
    if (widget.produto != null) {
      _nome.text = widget.produto!.nome;
      marcaSelecionada = widget.produto!.marca;
      _lote.text = widget.produto!.lote;
      fornecedorSelecionado = widget.produto!.fornecedor;
      _qtd.text = widget.produto!.quantidade.toString();
      _dataValidade = widget.produto!.validade;
    }
    _carregarListas();
  }

  Future<void> _carregarListas() async {
    final m = await _db.collection('marcas').orderBy('nome').get();
    final f = await _db.collection('fornecedores').orderBy('nome').get();
    setState(() {
      listaMarcas = m.docs.map((d) => DropdownMenuItem(value: d['nome'], child: Text(d['nome']))).toList();
      listaFornecedores = f.docs.map((d) => DropdownMenuItem(value: d['nome'], child: Text(d['nome']))).toList();
    });
  }

  Future<void> _salvar() async {
    if (_cod.text.isEmpty || _nome.text.isEmpty || marcaSelecionada == null || _lote.text.isEmpty || fornecedorSelecionado == null || _qtd.text.isEmpty || _dataValidade == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha todos os campos!')));
      return;
    }
    final dados = {
      'codigo': _cod.text.trim(),
      'nome': _nome.text.trim(),
      'marca': marcaSelecionada,
      'lote': _lote.text.trim(),
      'fornecedor': fornecedorSelecionado,
      'quantidade': int.parse(_qtd.text),
      'validade': _dataValidade,
    };
    if (widget.produto == null) {
      await _db.collection('produtos').add(dados);
    } else {
      await _db.collection('produtos').doc(widget.produto!.id).update(dados);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.produto == null ? 'Cadastrar Produto' : 'Editar Produto')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _cod, decoration: const InputDecoration(labelText: 'Código / Código de Barras', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _nome, decoration: const InputDecoration(labelText: 'Nome do Produto', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: marcaSelecionada,
              decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
              items: listaMarcas,
              onChanged: (v) => setState(() => marcaSelecionada = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _lote, decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: fornecedorSelecionado,
              decoration: const InputDecoration(labelText: 'Fornecedor', border: OutlineInputBorder()),
              items: listaFornecedores,
              onChanged: (v) => setState(() => fornecedorSelecionado = v),
            ),
            const SizedBox(height: 12),
            TextField(controller: _qtd, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder())),
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
            ElevatedButton(onPressed: _salvar, child: const Text('Salvar', style: TextStyle(fontSize: 18)))
          ],
        ),
      ),
    );
  }
}

class TelaConfiguracoes extends StatefulWidget {
  const TelaConfiguracoes({super.key});

  @override
  State<TelaConfiguracoes> createState() => _TelaConfiguracoesState();
}

class _TelaConfiguracoesState extends State<TelaConfiguracoes> {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _whatsapp = TextEditingController();
  bool alertaEmail = false;
  bool alertaWhats = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      final dados = doc.data()!;
      _whatsapp.text = dados['whatsapp'] ?? '';
      setState(() {
        alertaEmail = dados['alerta_email'] ?? false;
        alertaWhats = dados['alerta_whatsapp'] ?? false;
      });
    }
  }

  Future<void> _salvar() async {
    final uid = _auth.currentUser!.uid;
    await _db.collection('usuarios').doc(uid).update({
      'whatsapp': _whatsapp.text.trim(),
      'alerta_email': alertaEmail,
      'alerta_whatsapp': alertaWhats,
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações e Alertas')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(controller: _whatsapp, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'WhatsApp para alertas (apenas números)', border: OutlineInputBorder())),
            const SizedBox(height: 15),
            SwitchListTile(
              title: const Text('Receber alertas por e-mail'),
              value: alertaEmail,
              onChanged: (v) => setState(() => alertaEmail = v),
            ),
            SwitchListTile(
              title: const Text('Receber alertas por WhatsApp'),
              value: alertaWhats,
              onChanged: (v) => setState(() => alertaWhats = v),
            ),
            const SizedBox(height: 25),
            ElevatedButton(onPressed: _salvar, child: const Text('Salvar Configurações')),
            const SizedBox(height: 15),
            ListTile(
              title: const Text('Excluir minha conta', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.delete, color: Colors.red),
              onTap: () => _confirmarExclusao(),
            )
          ],
        ),
      ),
    );
  }

  void _confirmarExclusao() {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Excluir conta?'),
      content: const Text('Todos os seus dados serão apagados permanentemente.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        TextButton(onPressed: () async {
          final uid = _auth.currentUser!.uid;
          await _db.collection('usuarios').doc(uid).delete();
          await _auth.currentUser!.delete();
          if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
        }, child: const Text('Excluir', style: TextStyle(color: Colors.red))),
      ],
    ));
  }
}
