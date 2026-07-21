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
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutri Control'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => FirebaseAuth.instance.signOut()),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(decoration: BoxDecoration(color: Colors.green), child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [Icon(Icons.inventory_2, size: 50, color: Colors.white), Text('Nutri Control', style: TextStyle(color: Colors.white, fontSize: 22))])),
            ListTile(leading: const Icon(Icons.dashboard), title: const Text('Dashboard'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.list_alt), title: const Text('Produtos'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaProdutos())); }),
            ListTile(leading: const Icon(Icons.add_circle, color: Colors.green), title: const Text('Entrada'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaEntrada())); }),
            ListTile(leading: const Icon(Icons.remove_circle, color: Colors.red), title: const Text('Saída'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaSaida())); }),
            ListTile(leading: const Icon(Icons.picture_as_pdf), title: const Text('Relatórios'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (_) => const TelaRelatorios())); }),
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
          int vencidos = lista.where((d) => (d['validade'] as Timestamp).toDate().isBefore(hoje)).length;
          int vencem7 = lista.where((d) => (d['validade'] as Timestamp).toDate().difference(hoje).inDays <=7 && (d['validade'] as Timestamp).toDate().isAfter(hoje)).length;
          int vencem15 = lista.where((d) => (d['validade'] as Timestamp).toDate().difference(hoje).inDays <=15 && (d['validade'] as Timestamp).toDate().difference(hoje).inDays >7).length;
          int vencem30 = lista.where((d) => (d['validade'] as Timestamp).toDate().difference(hoje).inDays <=30 && (d['validade'] as Timestamp).toDate().difference(hoje).inDays >15).length;
          int baixo = lista.where((d) => d['quantidade'] <= 5).length;

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _card('Total Produtos', '$total', Icons.inventory, Colors.blue),
                _card('Vencidos', '$vencidos', Icons.warning, Colors.red),
                _card('Vencem em 7 dias', '$vencem7', Icons.access_time, Colors.orange),
                _card('Vencem em 15 dias', '$vencem15', Icons.schedule, Colors.amber),
                _card('Vencem em 30 dias', '$vencem30', Icons.date_range, Colors.lightGreen),
                _card('Estoque Baixo', '$baixo', Icons.trending_down, Colors.purple),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String titulo, String valor, IconData icone, Color cor) {
    return Card(elevation: 4, child: Padding(padding: const EdgeInsets.all(16), child: Column(mainAxisAlignment: MainAxisAlignment.center,children: [Icon(icone, size: 40, color: cor), const SizedBox(height: 8), Text(titulo, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13)), const SizedBox(height: 4), Text(valor, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: cor))])));
  }
}
