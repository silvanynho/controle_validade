import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class TelaRelatorios extends StatefulWidget {
  const TelaRelatorios({super.key});

  @override
  State<TelaRelatorios> createState() => _TelaRelatoriosState();
}

class _TelaRelatoriosState extends State<TelaRelatorios> {
  final db = FirebaseFirestore.instance;
  bool _carregando = false;

  Future<List<Map<String, dynamic>>> _buscarDadosProdutos() async {
    final res = await db.collection('produtos').orderBy('validade').get();
    return res.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  Future<List<Map<String, dynamic>>> _buscarMovimentacoes() async {
    final res = await db.collection('movimentacoes').orderBy('data_hora', descending: true).limit(200).get();
    return res.docs.map((d) => d.data() as Map<String, dynamic>).toList();
  }

  Future<void> _gerarPDF(String tipo) async {
    setState(() => _carregando = true);
    try {
      final pdf = pw.Document();
      final dados = tipo == 'produtos' ? await _buscarDadosProdutos() : await _buscarMovimentacoes();
      final hoje = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (contexto) => [
            pw.Header(text: 'Nutri Control - Relat贸rio ${tipo == 'produtos' ? 'Produtos' : 'Movimenta莽玫es'}', level: 1),
            pw.Paragraph(text: 'Gerado em: $hoje'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: tipo == 'produtos'
                  ? ['C贸digo', 'Lote', 'Marca', 'Validade', 'Quant']
                  : ['Tipo', 'C贸digo', 'Lote', 'Qtd', 'Resp', 'Data'],
              data: dados.map((item) {
                if (tipo == 'produtos') {
                  return [
                    item['codigo'] ?? '',
                    item['lote'] ?? '',
                    item['marca'] ?? '',
                    DateFormat('dd/MM/yyyy').format((item['validade'] as Timestamp).toDate()),
                    item['quantidade'].toString()
                  ];
                } else {
                  return [
                    item['tipo'] ?? '',
                    item['codigo'] ?? '',
                    item['lote'] ?? '',
                    item['quantidade'].toString(),
                    item['responsavel']?.split('@').first ?? '',
                    DateFormat('dd/MM/yyyy HH:mm').format((item['data_hora'] as Timestamp).toDate())
                  ];
                }
              }).toList(),
            ),
          ],
        ),
      );

      final dir = await getTemporaryDirectory();
      final caminho = '${dir.path}/relatorio_$tipo.pdf';
      final arquivo = File(caminho);
      await arquivo.writeAsBytes(await pdf.save());
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF gerado! Abrindo...'), backgroundColor: Colors.green));
        await OpenFile.open(caminho);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar PDF: $e')));
    } finally {
      if(mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _gerarExcel(String tipo) async {
    setState(() => _carregando = true);
    try {
      final excel = Excel.createExcel();
      excel.delete('Sheet1');
      final planilha = excel[tipo == 'produtos' ? 'Produtos' : 'Movimenta莽玫es'];
      final dados = tipo == 'produtos' ? await _buscarDadosProdutos() : await _buscarMovimentacoes();

      if (tipo == 'produtos') {
        planilha.appendRow(['C贸digo', 'Lote', 'Marca', 'Fornecedor', 'Validade', 'Quantidade']);
        for (var item in dados) {
          planilha.appendRow([
            item['codigo'] ?? '',
            item['lote'] ?? '',
            item['marca'] ?? '',
            item['fornecedor'] ?? '',
            DateFormat('dd/MM/yyyy').format((item['validade'] as Timestamp).toDate()),
            item['quantidade']
          ]);
        }
      } else {
        planilha.appendRow(['Tipo', 'C贸digo', 'Lote', 'Quantidade', 'Respons谩vel', 'Data/Hora']);
        for (var item in dados) {
          planilha.appendRow([
            item['tipo'] ?? '',
            item['codigo'] ?? '',
            item['lote'] ?? '',
            item['quantidade'],
            item['responsavel'] ?? '',
            DateFormat('dd/MM/yyyy HH:mm').format((item['data_hora'] as Timestamp).toDate())
          ]);
        }
      }

      final dir = await getTemporaryDirectory();
      final caminho = '${dir.path}/relatorio_$tipo.xlsx';
      final arquivo = File(caminho);
      await arquivo.writeAsBytes(excel.encode()!);
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel gerado! Abrindo...'), backgroundColor: Colors.green));
        await OpenFile.open(caminho);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar Excel: $e')));
    } finally {
      if(mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relat贸rios'), backgroundColor: Colors.green),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Escolha o tipo de relat贸rio:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _botaoRelatorio('馃搵 Relat贸rio de Produtos', Colors.blue, () => _mostrarOpcoes('produtos')),
                  const SizedBox(height: 12),
                  _botaoRelatorio('馃搳 Movimenta莽玫es (Entradas/Sa铆das)', Colors.purple, () => _mostrarOpcoes('movimentacoes')),
                  const SizedBox(height: 12),
                  _botaoRelatorio('鈿狅笍 Produtos Pr贸ximos ao Vencimento', Colors.orange, () => _mostrarOpcoes('produtos')),
                ],
              ),
            ),
    );
  }

  Widget _botaoRelatorio(String texto, Color cor, VoidCallback aoClicar) {
    return ElevatedButton(
      onPressed: aoClicar,
      style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: cor),
      child: Text(texto, style: const TextStyle(fontSize: 15)),
    );
  }

  void _mostrarOpcoes(String tipo) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Escolha o formato:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ListTile(leading: const Icon(Icons.picture_as_pdf, color: Colors.red), title: const Text('Gerar PDF'), onTap: () { Navigator.pop(context); _gerarPDF(tipo); }),
          ListTile(leading: const Icon(Icons.table_chart, color: Colors.green), title: const Text('Gerar Excel'), onTap: () { Navigator.pop(context); _gerarExcel(tipo); }),
        ]),
      ),
    );
  }
}
