import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../services/local_db.dart';

class PendingSyncScreen extends StatefulWidget {
  const PendingSyncScreen({super.key});

  @override
  State<PendingSyncScreen> createState() => _PendingSyncScreenState();
}

class _PendingSyncScreenState extends State<PendingSyncScreen> {
  List<Map<String, dynamic>> incidents = [];

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadPending();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ------------------------------------
  // CARGA LOCAL
  // ------------------------------------
  Future<void> _loadPending() async {
    incidents = await LocalDB.getPendingIncidents();

    print(">>> Pending incidents loaded: ${incidents.length}");
    for (var i in incidents) {
      print("ROW: $i");
    }

    setState(() {});
  }

  // ------------------------------------
  // POLLING CADA 10s
  // ------------------------------------
  void _startPolling() {
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) async {
        for (final incident in incidents) {
          final status = (incident['status'] ?? '').toString().toLowerCase();

          if (status == 'pendiente') {
            final clientId =
                incident['client_id'] ?? incident['clientId'];

            if (clientId != null) {
              await _checkIncidentStatus(clientId.toString());
            }
          }
        }
      },
    );
  }

  // ------------------------------------
  // CONSULTAR BACKEND
  // ------------------------------------
  Future<void> _checkIncidentStatus(String clientId) async {
    try {
      final res = await http.get(
        Uri.parse(
          'https://siaas-backend.onrender.com/sync/status/$clientId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final newStatus = (data['status'] ?? '').toString();

        if (newStatus == 'RECIBIDA') {
          print('>>> Incidente $clientId RECIBIDO por tópico');

          await LocalDB.updateIncidentStatusByLocalId(
            int.parse(clientId.toString()),
            "recibido",
    );

          await _loadPending();
        }
      }
    } catch (e) {
      debugPrint('Error consultando estado: $e');
    }
  }

  // ------------------------------------
  // ICONOS POR TIPO
  // ------------------------------------
  IconData _iconFor(String? type) {
    switch (type) {
      case 'picadura_abeja':
        return Icons.bug_report;
      case 'corte':
        return Icons.content_cut;
      case 'insolacion':
        return Icons.wb_sunny;
      case 'intoxicacion':
        return Icons.warning_amber;
      case 'caida':
        return Icons.directions_walk;
      default:
        return Icons.help_outline;
    }
  }

  // ------------------------------------
  // TEXTO BONITO
  // ------------------------------------
  String prettifyType(String type) {
    switch (type) {
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
        return type;
    }
  }

  // ------------------------------------
  // COLOR DEL ESTADO
  // ------------------------------------
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'recibida':
        return Colors.blue;
      case 'sincronizado':
        return Colors.green;
      case 'pendiente':
      default:
        return Colors.orange;
    }
  }

  // ------------------------------------
  // UI
  // ------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF5),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Cola de sincronización',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: incidents.isEmpty
          ? const Center(
        child: Text(
          'No hay incidentes pendientes',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: incidents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final item = incidents[i];

          final tipo = (item['tipo'] ?? 'desconocido').toString();
          final descripcion = (item['descripcion'] ?? '').toString();
          final hora = (item['hora'] ?? '00:00').toString();
          final status = (item['status'] ?? 'pendiente').toString();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(
                    _iconFor(tipo),
                    size: 30,
                    color: const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prettifyType(tipo),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Hora: $hora",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      if (descripcion.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          descripcion,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: _statusColor(status),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
