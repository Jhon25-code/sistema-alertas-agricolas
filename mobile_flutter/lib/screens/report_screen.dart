import 'package:flutter/material.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String type = 'picadura_abeja';
  String severity = 'medio';
  String locationMode = 'referencia';
  String description = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['type'] is String) {
      type = args['type'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = TimeOfDay.now().format(context);
    return Scaffold(
      appBar: AppBar(title: const Text('REPORTE DE INCIDENTE')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_labelFor(type), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('HORA: $hour'),
            const SizedBox(height: 8),
            Text('UBICACIÓN: Se añadirá al sincronizar'),
            const SizedBox(height: 12),
            const Text('Severidad'),
            Wrap(spacing: 8, children: [
              for (final s in ['leve','medio','grave'])
                ChoiceChip(label: Text(s), selected: severity==s, onSelected: (_)=> setState(()=> severity=s)),
            ]),
            const SizedBox(height: 12),
            TextFormField(
              maxLength: 160,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
              onChanged: (v)=> description = v,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD32F2F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () async {
                final score = _calcScore(type, severity);
                // TODO: Persistir en SQLite con estado 'pending' y hora local
                // TODO: Encolar para sincronización
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alerta creada (pendiente de sincronización)')));
                Navigator.pushNamed(context, '/pending');
              },
              child: const Text('ENVIAR'),
            )
          ],
        ),
      ),
    );
  }

  String _labelFor(String t) {
    switch (t) {
      case 'picadura_abeja': return 'Picadura de abeja';
      case 'corte': return 'Corte';
      case 'insolacion': return 'Insolación';
      case 'intoxicacion': return 'Intoxicación';
      case 'caida': return 'Caída';
      default: return 'Otros';
    }
  }

  int _calcScore(String t, String sev) {
    int base = {'leve':20,'medio':60,'grave':90}[sev] ?? 20;
    if (t=='picadura_abeja') base = 70 if (sev=='medio') else base;
    if (t=='intoxicacion') base += 10;
    return base.clamp(0,100);
  }
}
