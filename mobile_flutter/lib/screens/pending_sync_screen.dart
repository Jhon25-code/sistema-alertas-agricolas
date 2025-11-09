import 'package:flutter/material.dart';

class PendingSyncScreen extends StatelessWidget {
  const PendingSyncScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final items = [
      {'id': 'loc-1', 'status': 'pending', 'score': 85},
      {'id': 'loc-2', 'status': 'synced', 'score': 55},
    ];
    Color badge(String s){
      switch (s) {
        case 'pending': return Colors.orange;
        case 'synced': return Colors.green;
        case 'failed': return Colors.red;
        default: return Colors.grey;
      }
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Cola de sincronización')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __)=> const Divider(height: 1),
        itemBuilder: (_, i){
          final it = items[i];
          return ListTile(
            title: Text('Incidente ${it['id']}'),
            subtitle: Text('smart_score: ${it['score']}'),
            trailing: CircleAvatar(backgroundColor: badge('${it['status']}')),
          );
        },
      ),
    );
  }
}
