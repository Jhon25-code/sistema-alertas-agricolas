import 'package:flutter/material.dart';

class IncidentTypeScreen extends StatefulWidget {
  const IncidentTypeScreen({super.key});
  @override
  State<IncidentTypeScreen> createState() => _IncidentTypeScreenState();
}

class _IncidentTypeScreenState extends State<IncidentTypeScreen> {
  final types = [
    ['picadura_abeja','Picadura','icons_bee.png'],
    ['corte','Corte','icons_cut.png'],
    ['insolacion','Insolación','icons_sun.png'],
    ['intoxicacion','Intoxicación','icons_skull.png'],
    ['caida','Caída','icons_fall.png'],
    ['otro','Otros','icons_other.png'],
  ];
  String? selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TIPO DE INCIDENTE')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  for (final t in types) InkWell(
                    onTap: ()=> setState(()=> selected = t[0]),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected==t[0] ? Colors.blue : Colors.grey.shade300, width: 2),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/${t[2]}', height: 72, errorBuilder: (_, __, ___)=> const Icon(Icons.image_not_supported, size: 72)),
                          const SizedBox(height: 8),
                          Text(t[1], style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selected==null ? null : () => Navigator.pushNamed(context, '/report', arguments: {'type': selected}),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1976D2)),
                child: const Text('SIGUIENTE'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
