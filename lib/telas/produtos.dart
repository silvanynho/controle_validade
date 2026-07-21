import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  final db = FirebaseFirestore.instance;
  final _codigo = TextEditingController();
  final _categoria = TextEditingController();
  final _marca = TextEditingController();
  final _fornecedor = TextEditingController();
  final _lote = TextEditingController();
  final _fabricacao = TextEditingController();
  final _validade = TextEditingController();
  final _quantidade = TextEditingController();
  final _observacoes = TextEditingController();
  DateTime? _dataFab;
  DateTime? _dataVal;
  String? _idEditar;
  bool _escaneando = false;

  Future<void> _salvar() async {
    if (_codigo.text.isEmpty || _lote.text.isEmpty || _dataVal == null || _quantidade.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os campos obrigatórios!')));
      return;
    }
    final dados = {
      'codigo': _codigo.text.trim(),
      'categoria': _categoria.text.trim(),
      'marca': _marca.text.trim(),
      'fornecedor': _fornecedor.text.trim(),
      'lote': _lote.text.trim(),
      'fabricacao': _dataFab != null ? Timestamp.fromDate(_dataFab!) : null,
      'validade': Timestamp.fromDate(_dataVal!),
      'quantidade': int.parse(_quantidade.text.trim()),
      'observacoes': _observacoes.text.trim(),
      'ultima_alteracao': FieldValue.serverTimestamp(),
    };

    if (_idEditar != null) {
      await db.collection('produtos').doc(_idEditar).update(dados);
    } else {
      await db.collection('produtos').add(dados);
    }
    _limparCampos();
    Navigator.pop(context);
  }

  void _limparCampos() {
    _codigo.clear();
    _categoria.clear();
    _marca.clear();
    _fornecedor.clear();
    _lote.clear();
    _fabricacao.clear();
    _validade.clear();
    _quantidade.clear();
    _observacoes.clear();
    _dataFab = null;
    _dataVal = null;
    _idEditar = null;
  }

  void _abrirFormulario([DocumentSnapshot? item]) {
    _limparCampos();
    if (item != null) {
      final d = item.data() as Map<String, dynamic>;
      _idEditar = item.id;
      _codigo.text = d['codigo'] ?? '';
      _categoria.text = d['categoria'] ?? '';
      _marca.text = d['marca'] ?? '';
      _fornecedor.text = d['fornecedor'] ?? '';
      _lote.text = d['lote'] ?? '';
      _dataFab = d['fabricacao'] != null ? (d['fabricacao'] as Timestamp).toDate() : null;
      _dataVal = (d['validade'] as Timestamp).toDate();
      _quantidade.text = d['quantidade'].toString();
      _observacoes.text = d['observacoes'] ?? '';
      if (_dataFab != null) _fabricacao.text = DateFormat('dd/MM/yyyy').format(_dataFab!);
      _validade.text = DateFormat('dd/MM/yyyy').format(_dataVal!);
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_idEditar == null ? 'Cadastrar Produto' : 'Editar Produto', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: TextField(controller: _codigo, decoration: const InputDecoration(labelText: 'Código de Barras', border: OutlineInputBorder()))),
                IconButton(icon: const Icon(Icons.qr_code_scanner), onPressed: () => setModal(() => _escaneando = true))
              ]),
              if (_escaneando)
                SizedBox(height: 200, child: MobileScanner(onDetect: (c) {
                  if (c.barcodes.isNotEmpty) {
                    _codigo.text = c.barcodes.first.rawValue ?? '';
                    setModal(() => _escaneando = false);
                  }
                })),
              const SizedBox(height: 8),
              TextField(controller: _categoria, decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _marca, decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _fornecedor, decoration: const InputDecoration(labelText: 'Fornecedor', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _lote, decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _fabricacao, readOnly: true, onTap: () async {
                final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime.now());
                if (d != null) setModal(() { _dataFab = d; _fabricacao.text = DateFormat('dd/MM/yyyy').format(d); });
              }, decoration: const InputDecoration(labelText: 'Data Fabricação', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today))),
              const SizedBox(height: 8),
              TextField(controller: _validade, readOnly: true, onTap: () async {
             final d = await showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime.now(),
  lastDate: DateTime(2035)
);
                if (d != null) setModal(() { _dataVal = d; _validade.text = DateFormat('dd/MM/yyyy').format(d); });
              }, decoration: const InputDecoration(labelText: 'Data Validade *', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today))),
              const SizedBox(height: 8),
              TextField(controller: _quantidade, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade *', border: OutlineInputBorder())),
              const SizedBox(height: 8),
              TextField(controller: _observacoes, maxLines: 2, decoration: const InputDecoration(labelText: 'Observações', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _salvar, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical:12)), child: Text(_idEditar == null ? 'Cadastrar' : 'Atualizar')))
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produtos'), backgroundColor: Colors.green),
      floatingActionButton: FloatingActionButton(onPressed: _abrirFormulario, backgroundColor: Colors.green, child: const Icon(Icons.add)),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('produtos').orderBy('validade').snapshots(),
        builder: (c, s) {
          if (!s.hasData) return const Center(child: CircularProgressIndicator());
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: s.data!.docs.length,
            itemBuilder: (c, i) {
              final item = s.data!.docs[i];
              final d = item.data() as Map<String, dynamic>;
              final val = (d['validade'] as Timestamp).toDate();
              final dias = val.difference(DateTime.now()).inDays;
              return Card(
                child: ListTile(
                  title: Text('${d['codigo']} - ${d['lote']}'),
                  subtitle: Text('Qtd: ${d['quantidade']} | Val: ${DateFormat('dd/MM/yyyy').format(val)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _abrirFormulario(item)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                      if (await showDialog(context: context, builder: (_) => AlertDialog(title: const Text('Excluir?'), actions: [TextButton(onPressed: ()=>Navigator.pop(context,false), child: const Text('Não')), TextButton(onPressed: ()=>Navigator.pop(context,true), child: const Text('Sim'))])) == true) {
                        await db.collection('produtos').doc(item.id).delete();
                      }
                    })
                  ]),
                  leading: Icon(Icons.inventory, color: dias < 0 ? Colors.red : dias <=7 ? Colors.orange : Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
