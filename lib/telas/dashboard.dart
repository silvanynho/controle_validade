import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'produtos.dart';
import 'entradas.dart';
import 'saidas.dart';
import 'relatorios.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutri Control'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sair',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 50, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Nutri Control', style: TextStyle(color: Colors.white, fontSize: 22)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Produtos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaProdutos()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),
              title: const Text('Entrada de Estoque'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrada()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove_circle, color: Colors.red),
              title: const Text('Saída de Estoque'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSaida()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Relatórios'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRelatorios()));
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db.collection('produtos').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final lista = snapshot.data!.docs;
          final hoje = DateTime.now();

          int total = lista.length;
          int vencidos = 0;
          int vencem7 = 0;
          int vencem15 = 0;
          int vencem30 = 0;
          int estoqueBaixo = 0;

          for (var item in lista) {
            final dados = item.data() as Map<String, dynamic>;
            final validade = (dados['validade'] as Timestamp).toDate();
            final qtd = dados['quantidade'] as int;
            final dias = validade.difference(hoje).inDays;

            if (validade.isBefore(hoje)) {
              vencidos++;
            } else if (dias <= 7) {
              vencem7++;
            } else if (dias <= 15) {
              vencem15++;
            } else if (dias <= 30) {
              vencem30++;
            }

            if (qtd <= 5) estoqueBaixo++;
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _card('Total de Produtos', '$total', Icons.inventory, Colors.blue),
                _card('Vencidos', '$vencidos', Icons.warning, Colors.red),
                _card('Vencem em até 7 dias', '$vencem7', Icons.access_time, Colors.orange),
                _card('Vencem em até 15 dias', '$vencem15', Icons.schedule, Colors.amber),
                _card('Vencem em até 30 dias', '$vencem30', Icons.date_range, Colors.lightGreen),
                _card('Estoque Baixo', '$estoqueBaixo', Icons.trending_down, Colors.purple),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String titulo, String valor, IconData icone, Color cor) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 40, color: cor),
            const SizedBox(height: 8),
            Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
      ),
    );
  }
}
