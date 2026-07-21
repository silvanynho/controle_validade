import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class TelaSaida extends StatefulWidget {
  const TelaSaida({super.key});

  @override
  State<TelaSaida> createState() => _TelaSaidaState();
}

class _TelaSaidaState extends State<TelaSaida> {
  final db = FirebaseFirestore.instance;
  final _codigo = TextEditingController();
  final _quantidade = TextEditingController();
  DocumentSnapshot? _produtoEncontrado;

  Future<void> _escanearCodigo() async {
    try {
      var resultado = await BarcodeScanner.scan();
      if (resultado.raw.isNotEmpty) {
        setState(() => _codigo.text = resultado.rawContent);
        _buscarProduto();
      }
    } catch (_) {}
  }

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
        const SnackBar(content: Text('Produto não encontrado!'))
      );
    }
  }

  Future<void> _registrarSaida() async {
    if (_produtoEncontrado == null || _quantidade.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos!'))
      );
      return;
    }
    final qtdRetirar = int.parse(_quantidade.text.trim());
    final dadosProd = _produtoEncontrado!.data() as Map<String, dynamic>;
    final qtdAtual = dadosProd['quantidade'] as int;

    if (qtdRetirar > qtdAtual) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantidade insuficiente em estoque!'), backgroundColor: Colors.red)
      );
      return;
    }

    await db.runTransaction((transacao) async {
      transacao.update(_produtoEncontrado!.reference, {
        'quantidade': qtdAtual - qtdRetirar,
        'ultima_saida': FieldValue.serverTimestamp()
      });
      transacao.set(db.collection('movimentacoes').doc(), {
        'tipo': 'SAÍDA',
        'codigo': _codigo.text.trim(),
        'lote': dadosProd['lote'],
        'quantidade': qtdRetirar,
        'responsavel': FirebaseAuth.instance.currentUser?.email ?? 'Desconhecido',
        'data_hora': FieldValue.serverTimestamp()
      });
    });

    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saída registrada com sucesso!'), backgroundColor: Colors.green)
      );
      _codigo.clear(); _quantidade.clear();
      setState(() => _produtoEncontrado = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saída de Estoque'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _codigo,
                    decoration: const InputDecoration(labelText: 'Código de Barras', border: OutlineInputBorder())
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
                  onPressed: _escanearCodigo,
                  style: IconButton.styleFrom(backgroundColor: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_produtoEncontrado != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red)
                ),
                child: Text(
                  'Produto: ${(_produtoEncontrado!.data() as Map<String,dynamic>)['lote']}\nEstoque atual: ${(_produtoEncontrado!.data() as Map<String,dynamic>)['quantidade']}',
                  style: const TextStyle(color: Colors.red, fontSize: 15),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _quantidade,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantidade a retirar', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _registrarSaida,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical:14), backgroundColor: Colors.red),
                child: const Text('Registrar Saída', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
