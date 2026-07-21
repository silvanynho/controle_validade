import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';

class TelaEntrada extends StatefulWidget {
  const TelaEntrada({super.key});

  @override
  State<TelaEntrada> createState() => _TelaEntradaState();
}

class _TelaEntradaState extends State<TelaEntrada> {
  final db = FirebaseFirestore.instance;
  final _codigo = TextEditingController();
  final _lote = TextEditingController();
  final _quantidade = TextEditingController();
  bool _escaneando = false;
  DocumentSnapshot? _produtoEncontrado;

  Future<void> _buscarProduto() async {
    if (_codigo.text.trim().isEmpty) return;
    final res = await db.collection('produtos')
        .where('codigo', isEqualTo: _codigo.text.trim())
        .limit(1)
        .get();
    if (res.docs.isNotEmpty) {
      setState(() => _produtoEncontrado = res.docs.first);
    } else {
      setState(() => _produtoEncontrado = null);
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto não encontrado! Cadastre-o primeiro.'))
      );
    }
  }

  Future<void> _registrarEntrada() async {
    if (_produtoEncontrado == null || _quantidade.text.isEmpty || _lote.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos e selecione o produto!'))
      );
      return;
    }
    final qtdAdd = int.parse(_quantidade.text.trim());
    final dadosProd = _produtoEncontrado!.data() as Map<String, dynamic>;
    final qtdAtual = dadosProd['quantidade'] as int;

    await db.runTransaction((transacao) async {
      transacao.update(_produtoEncontrado!.reference, {
        'quantidade': qtdAtual + qtdAdd,
        'lote': _lote.text.trim(),
        'ultima_entrada': FieldValue.serverTimestamp()
      });
      transacao.set(db.collection('movimentacoes').doc(), {
        'tipo': 'ENTRADA',
        'codigo': _codigo.text.trim(),
        'lote': _lote.text.trim(),
        'quantidade': qtdAdd,
        'responsavel': FirebaseAuth.instance.currentUser?.email ?? 'Desconhecido',
        'data_hora': FieldValue.serverTimestamp()
      });
    });

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrada registrada com sucesso!'), backgroundColor: Colors.green)
      );
      _codigo.clear();
      _lote.clear();
      _quantidade.clear();
      setState(() => _produtoEncontrado = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrada de Estoque'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigo,
                    decoration: const InputDecoration(
                      labelText: 'Código de Barras',
                      border: OutlineInputBorder()
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.search),
                  onPressed: _buscarProduto,
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
                IconButton.filled(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => setState(() => _escaneando = true),
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            if (_escaneando)
              SizedBox(
                height: 200,
                child: MobileScanner(
                  onDetect: (captura) {
                    if (captura.barcodes.isNotEmpty) {
                      _codigo.text = captura.barcodes.first.rawValue ?? '';
                      setState(() => _escaneando = false);
                      _buscarProduto();
                    }
                  },
                ),
              ),
            const SizedBox(height: 12),
            if (_produtoEncontrado != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green)
                ),
                child: Text(
                  'Produto encontrado!\nLote atual: ${(_produtoEncontrado!.data() as Map<String,dynamic>)['lote']}\nEstoque atual: ${(_produtoEncontrado!.data() as Map<String,dynamic>)['quantidade']}',
                  style: const TextStyle(color: Colors.green, fontSize: 15),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _lote,
              decoration: const InputDecoration(labelText: 'Novo Lote', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantidade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade a adicionar', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registrarEntrada,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical:14),
                  backgroundColor: Colors.green
                ),
                child: const Text('Registrar Entrada', style: TextStyle(fontSize: 18)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
