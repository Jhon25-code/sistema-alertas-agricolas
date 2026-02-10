import 'package:flutter/material.dart';
import 'package:siaas/services/local_db.dart'; // Asegúrate de que esta ruta sea correcta
import 'package:siaas/services/sync_service.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  // Aquí guardaremos la lista de incidentes para mostrarla
  List<Map<String, dynamic>> _incidentes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Función para leer la base de datos local
  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    // Usamos la misma función que usa tu servicio para ver qué hay pendiente
    final data = await LocalDB.getPendingIncidents();
    setState(() {
      _incidentes = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cola de sincronización"),
        backgroundColor: Colors.blue, // Color corporativo
        foregroundColor: Colors.white,
        actions: [
          // --- AQUÍ ESTÁ EL BOTÓN QUE PEDISTE ---
          IconButton(
            icon: const Icon(Icons.sync), // Icono de flechas girando
            tooltip: "Sincronizar ahora",
            onPressed: () async {
              // 1. Avisar al usuario
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Intentando enviar datos...'),
                  duration: Duration(seconds: 1),
                ),
              );

              // 2. LLAMAR A TU SERVICIO (La magia)
              await SyncService().syncNow();

              // 3. Recargar la lista para ver cambios (ej: si pasaron a ENVIADO)
              await _cargarDatos();

              // 4. Confirmación visual
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Proceso finalizado')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _incidentes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 60, color: Colors.green),
                      SizedBox(height: 10),
                      Text("¡Todo sincronizado!",
                          style: TextStyle(fontSize: 18)),
                      Text("No hay datos pendientes de envío.",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _incidentes.length,
                  itemBuilder: (context, index) {
                    final item = _incidentes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange),
                        title: Text(item['tipo'] ?? 'Incidente'),
                        subtitle:
                            Text(item['descripcion'] ?? 'Sin descripción'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cloud_upload,
                                color: Colors.grey, size: 20),
                            Text(
                              "Pendiente",
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
