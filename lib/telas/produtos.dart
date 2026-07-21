import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class TelaProdutos extends StatefulWidget {
  const TelaProdutos({super.key});

  @override
  State<TelaProdutos> createState() => _TelaProdutosState();
}

class _TelaProdutosState extends State<TelaProdutos> {
  final db = FirebaseFirestore.instance;
  final _codigo = TextEditingController();
  final _lote = TextEditingController();
  final _marca = TextEditingController();
  final _fornecedor = TextEditingController();
  final _quantidade = TextEditingController();
  DateTime? _validade;
  final _formKey = GlobalKey<FormState>();

  Future<void> _escanearCodigo() async {
    try {
      final resultado = await BarcodeScanner.scan();
      if (resultado.rawContent.isNotEmpty) {
        setState(() => _codigo.text = resultado.rawContent);
      }
    } catch (_) {}
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate() || _validade == null) return;
    await db.collection('produtos').add({
      'codigo': _codigo.text.trim(),
      'lote': _lote.text.trim(),
      'marca': _marca.text.trim(),
      'fornecedor': _fornecedor.text.trim(),
      'quantidade': int.parse(_quantidade.text),
      'validade': Timestamp.fromDate(_validade!),
      'data_cadastro': FieldValue.serverTimestamp()
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produto cadastrado!'), backgroundColor: Colors.green)
    );
    _limpar();
  }

  void _limpar() {
    _codigo.clear(); _lote.clear(); _marca.clear(); _fornecedor.clear(); _quantidade.clear();
    setState(() => _validade = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro de Produtos'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _codigo,
                      decoration: const InputDecoration(labelText: 'Código', border: OutlineInputBorder())
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, size: 32, color: Colors.green),
                    onPressed: _escanearCodigo
                  )
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lote,
                decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _marca,
                decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _fornecedor,
                decoration: const InputDecoration(labelText: 'Fornecedor', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantidade,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantidade', border: OutlineInputBorder())
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2035)
                  );
                  if(d!=null) setState(() => _validade = d);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Validade', border: OutlineInputBorder()),
                  child: Text(_validade==null?'Selecione...':DateFormat('dd/MM/yyyy').format(_validade!))
                )
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _salvar,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(14), backgroundColor: Colors.green),
                  child: const Text('Cadastrar', style: TextStyle(fontSize: 18))
                )
              )
            ],
          ),
        ),
      ),
    );
  }
}
