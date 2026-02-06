import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // <--- IMPORTANTE: Agregamos esto
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
  bool _isSaving = false; // Para evitar doble clic

  //  HORA SEGURA
  String _getSafeHour() {
    final now = DateTime.now();
    return "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['type'] is String) {
      type = args['type'];
    }
  }

  /// Función auxiliar para obtener posición actual
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Ver si el GPS está prendido
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Intenta pedirle al usuario que lo prenda
      return Future.error('El servicio de ubicación está desactivado.');
    }

    // 2. Ver permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Permiso de ubicación denegado.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Permiso de ubicación denegado permanentemente.');
    }

    // 3. Obtener ubicación (High accuracy para mejor precisión)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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

            // -------------------- Nombre --------------------
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
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "UBICACIÓN: Se detectará al enviar...",
                style: TextStyle(fontSize: 14, color: Colors.grey),
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
                  backgroundColor: _isSaving ? Colors.grey : const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                // Si está guardando, desactivamos el botón
                onPressed: _isSaving ? null : () async {
                  setState(() => _isSaving = true); // Bloquear botón

                  // 1. Feedback visual inmediato
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Obteniendo ubicación GPS... por favor espere'),
                      duration: Duration(seconds: 2),
                    ),
                  );

                  double? lat;
                  double? lng;
                  String ubicacionTexto = "Sin GPS";

                  try {
                    // 2. Intentar obtener GPS
                    Position? position = await _determinePosition();
                    if (position != null) {
                      lat = position.latitude;
                      lng = position.longitude;
                      ubicacionTexto = "$lat, $lng";
                      print("✅ GPS Obtenido: $lat, $lng");
                    }
                  } catch (e) {
                    print("❌ Error obteniendo GPS: $e");
                    // Opcional: Mostrar alerta si falla mucho
                    // Pero dejamos que guarde null para no bloquear al usuario,
                    // aunque el SyncService lo ignorará después.
                  }

                  // 3. Preparar datos (CON lat y lng)
                  final incidente = {
                    "tipo": type,
                    "descripcion": description,
                    "ubicacion": ubicacionTexto, // Texto visual
                    "hora": hour,
                    "prioridad": severity,
                    "fotoPath": "",
                    // -- CLAVES CRÍTICAS PARA LA SINCRONIZACIÓN --
                    "lat": lat,
                    "lng": lng,
                  };

                  print("💾 Datos a guardar: $incidente");

                  // 4. Guardar en BD
                  final id = await LocalDB.saveIncident(incidente);
                  print("✅ Guardado con ID $id");

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lat != null
                          ? 'Incidente guardado con GPS'
                          : 'Guardado SIN GPS (No se enviará)'),
                      backgroundColor: lat != null ? Colors.green : Colors.orange,
                    ),
                  );

                  // 5. Ir a pantalla de cola
                  Navigator.pushReplacementNamed(context, '/pending');
                },
                child: _isSaving
                    ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                )
                    : const Text(
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

  // Helpers de nombre e imagen se mantienen igual...
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

  String _imageFor(String t) {
    switch (t) {
      case 'picadura_abeja': return 'assets/icons/icons_bee.png';
      case 'corte': return 'assets/icons/icons_cut.png';
      case 'insolacion': return 'assets/icons/icons_sun.png';
      case 'intoxicacion': return 'assets/icons/icons_skull.png';
      case 'caida': return 'assets/icons/icons_fall.png';
      default: return 'assets/icons/icons_other.png';
    }
  }
}