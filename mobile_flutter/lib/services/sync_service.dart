import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

import 'local_db.dart';
import 'package:siaas/config/api_config.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isSyncing = false;

  /// URL backend
  static final String _backendUrl = "${ApiConfig.baseUrl}/incidents";

  // =========================================================
  // INICIAR ESCUCHA DE CONECTIVIDAD
  // =========================================================
  Future<void> startSyncListener() async {
    print('🔄 SyncService ACTIVADO');

    // Evitar listeners duplicados
    await _subscription?.cancel();
    _subscription = null;

    // Cargar token guardado (NO hace login)
    await AuthService.init();

    final token = AuthService.token;
    if (token == null || token.isEmpty) {
      print('⛔ SyncService NO iniciado: usuario no logueado');
      return;
    }

    // Chequeo inicial REAL
    final initial = await _connectivity.checkConnectivity();
    print('📡 Conectividad inicial: $initial');

    if (initial != ConnectivityResult.none) {
      await syncNow();
    }

    _subscription =
        _connectivity.onConnectivityChanged.listen((ConnectivityResult result) async {
          print('📡 Conectividad detectada: $result');

          if (result != ConnectivityResult.none) {
            await syncNow();
          }
        });
  }

  // =========================================================
  // SINCRONIZACIÓN PRINCIPAL
  // =========================================================
  Future<void> syncNow() async {
    if (_isSyncing) return;

    _isSyncing = true;
    print('🚀 Iniciando sincronización...');

    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        print('⛔ Cancelado: no hay token');
        return;
      }

      final preview = token.length > 10 ? token.substring(0, 10) : token;
      print('🔑 Token activo: $preview... (len=${token.length})');

      final pending = await LocalDB.getPendingIncidents();
      print('📦 Incidentes pendientes: ${pending.length}');

      if (pending.isEmpty) return;

      for (final incident in pending) {
        try {
          final lat = incident['lat'];
          final lng = incident['lng'];

          if (lat == null || lng == null) {
            print('⚠️ Incidente ${incident['local_id']} sin GPS. Omitido.');
            continue;
          }

          final payload = {
            'tipo': incident['tipo'],
            'descripcion': incident['descripcion'],
            'latitude': lat,
            'longitude': lng,
            'smart_score': incident['smart_score'],
          };

          print('📤 Enviando incidente ${incident['local_id']}');
          print('📤 Payload: ${jsonEncode(payload)}');

          final response = await http
              .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(payload),
          )
              .timeout(const Duration(seconds: 20));

          print('🔙 Status: ${response.statusCode}');
          print('🔙 Body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            await LocalDB.updateIncidentStatusByLocalId(
              incident['local_id'],
              'ENVIADO',
            );
            await LocalDB.markAsSynced(incident['id']);

            print('✅ Incidente sincronizado');

            await HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 80));
            await HapticFeedback.heavyImpact();
          } else if (response.statusCode == 401) {
            print('⛔ Token inválido o vencido. Requiere login.');
            return;
          } else {
            print('❌ Error servidor: ${response.body}');
          }
        } on TimeoutException {
          print('⏱️ Timeout (backend dormido o red lenta)');
        } catch (e) {
          print('🔥 Error enviando incidente: $e');
        }
      }
    } catch (e) {
      print('🔥 Error general SyncService: $e');
    } finally {
      _isSyncing = false;
      print('🏁 Sincronización finalizada');
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
