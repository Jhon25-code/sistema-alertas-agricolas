import 'package:flutter/material.dart';
import '../services/local_db.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String type = 'picadura_abeja';
  String severity = 'medio';
  String description = "";

  //  HORA SEGURA
  String _getSafeHour() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null && args['type'] is String) {
      type = args['type'];
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = _getSafeHour();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5EC),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          //  REGRESAR SIEMPRE A TIPO DE INCIDENTE
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/incident_type');
          },
        ),
        centerTitle: true,
        title: const Text(
          'REPORTE DE INCIDENTE',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // -------------------- Imagen --------------------
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1976D2), width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                _imageFor(type),
                height: 180,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 10),

            // -------------------- Nombre del incidente --------------------
            Text(
              _labelFor(type),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            // -------------------- Hora --------------------
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "HORA: $hour",
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 4),

            // -------------------- Ubicación --------------------
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "UBICACIÓN: Se añadirá al sincronizar",
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 20),

            // -------------------- Severidad --------------------
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Severidad", style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 8),

            Wrap(
              spacing: 10,
              children: [
                for (final s in ['leve', 'medio', 'grave'])
                  ChoiceChip(
                    label: Text(s),
                    selected: severity == s,
                    onSelected: (_) => setState(() => severity = s),
                  ),
              ],
            ),

            const SizedBox(height: 20),

            // -------------------- Descripción --------------------
            TextFormField(
              maxLength: 160,
              decoration: const InputDecoration(
                labelText: 'Descripción (opcional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => description = v.toString(),
            ),

            const SizedBox(height: 30),

            // -------------------- BOTÓN ENVIAR --------------------
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () async {
                  print(" ENVIAR PRESIONADO");

                  final incidente = {
                    "tipo": type,
                    "descripcion": description,
                    "ubicacion": "pendiente",
                    "hora": hour,
                    "prioridad": severity,
                    "fotoPath": "",
                  };

                  print(" Datos a guardar: $incidente");
                  print(" Guardando en SQLite...");

                  final id = await LocalDB.saveIncident(incidente);

                  print(" Guardado con ID $id");

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Incidente guardado (pendiente de sincronización)'),
                    ),
                  );

                  Navigator.pushReplacementNamed(context, '/pending');
                },
                child: const Text(
                  'ENVIAR',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  //  Nombre visible del incidente
  // ----------------------------------------------------------
  String _labelFor(String t) {
    switch (t) {
      case 'picadura_abeja':
        return 'Picadura de abeja';
      case 'corte':
        return 'Corte';
      case 'insolacion':
        return 'Insolación';
      case 'intoxicacion':
        return 'Intoxicación';
      case 'caida':
        return 'Caída';
      default:
        return 'Otros';
    }
  }

  // ----------------------------------------------------------
  //  Icono según el tipo
  // ----------------------------------------------------------
  String _imageFor(String t) {
    switch (t) {
      case 'picadura_abeja':
        return 'assets/icons/icons_bee.png';
      case 'corte':
        return 'assets/icons/icons_cut.png';
      case 'insolacion':
        return 'assets/icons/icons_sun.png';
      case 'intoxicacion':
        return 'assets/icons/icons_skull.png';
      case 'caida':
        return 'assets/icons/icons_fall.png';
      default:
        return 'assets/icons/icons_other.png';
    }
  }
}
