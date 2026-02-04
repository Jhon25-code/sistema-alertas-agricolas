import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
// ✅ 1. CAMBIO: Usamos vibración nativa (cero errores)
import 'package:flutter/services.dart';

import 'local_db.dart';
import 'package:siaas/config/api_config.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();

  /// Connectivity v6+
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isSyncing = false;

  /// URL backend
  static final String _backendUrl = "${ApiConfig.baseUrl}/incidents";

  /// ===============================
  /// INICIAR ESCUCHA DE CONECTIVIDAD
  /// ===============================
  Future<void> startSyncListener() async {
    print('🔄 SyncService ACTIVADO');

    await AuthService.init();

    _subscription =
        _connectivity.onConnectivityChanged.listen((results) async {
          print('📡 Conectividad: $results');

          if (!results.contains(ConnectivityResult.none)) {
            await syncNow();
          }
        });
  }

  /// ===============================
  /// SINCRONIZACIÓN PRINCIPAL
  /// ===============================
  Future<void> syncNow() async {
    if (_isSyncing) {
      print('⏳ Sincronización en curso...');
      return;
    }

    _isSyncing = true;
    print('🚀 Iniciando sincronización');

    await AuthService.init();
    final token = AuthService.token;

    if (token == null) {
      print('❌ No hay token');
      _isSyncing = false;
      return;
    }

    final pending = await LocalDB.getPendingIncidents();
    print('📦 Incidentes pendientes: ${pending.length}');

    if (pending.isEmpty) {
      print('✅ Nada que sincronizar');
      _isSyncing = false;
      return;
    }

    for (final incident in pending) {
      try {
        final payload = {
          'tipo': incident['tipo'],
          'descripcion': incident['descripcion'],
          'latitude': incident['lat'],
          'longitude': incident['lng'],
          'smart_score': incident['smart_score'],
          'local_id': incident['local_id'], // 🔥 CLAVE
        };

        print('➡️ Enviando incidente: $payload');

        final response = await http.post(
          Uri.parse(_backendUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          // ✅ CAMBIO CLAVE
          await LocalDB.updateIncidentStatusByLocalId(
            incident['local_id'],
            'NUEVA',
          );

          await LocalDB.markAsSynced(incident['id']);

          print('✅ Sincronizado local_id ${incident['local_id']}');

          // ✅ INNOVACIÓN: Feedback Háptico "Latido" (Nativo)
          // Vibra 3 veces fuerte para confirmar que salió del teléfono (tic-tic-tic)
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.heavyImpact();
          await Future.delayed(const Duration(milliseconds: 150));
          await HapticFeedback.heavyImpact();

        } else {
          print('❌ Error backend ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('🔥 Error sincronizando incidente: $e');
      }
    }

    _isSyncing = false;
    print('🏁 Sincronización finalizada');
  }

  void stop() {
    _subscription?.cancel();
  }
}