import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

import 'local_db.dart';
import 'package:siaas/config/api_config.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();

  /// ⚠️ TIPO CORRECTO (Connectivity v6+)
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isSyncing = false;

  /// URL backend (Render)
  static final String _backendUrl = "${ApiConfig.baseUrl}/incidents";

  /// Inicia escucha automática (UNA SOLA VEZ)
  /// 🔐 FIX: asegurar token antes de sincronizar
  Future<void> startSyncListener() async {
    print('🔄 SyncService ACTIVADO');

    // 🔐 ASEGURAR LOGIN ANTES DE ESCUCHAR CONECTIVIDAD
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

    // 🔐 Asegurar token
    await AuthService.init();

    final token = AuthService.token;
    if (token == null) {
      print('❌ No hay token, no se puede sincronizar');
      _isSyncing = false;
      return;
    }

    final pending = await LocalDB.getPendingIncidents();
    print('📦 Incidentes pendientes: ${pending.length}');

    for (final incident in pending) {
      try {
        final payload = {
          'tipo': incident['tipo'],
          'descripcion': incident['descripcion'],
          'latitude': incident['lat'],
          'longitude': incident['lng'],
          'smart_score': incident['smart_score'],
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
          await LocalDB.markAsSynced(incident['id']);
          print('✅ Sincronizado ID ${incident['id']}');
        } else {
          print('❌ Error backend ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        print('🔥 Error sincronizando: $e');
      }
    }

    // 🔥 NUEVO: sincronizar estados desde backend
    await syncStatusesFromServer(token);

    _isSyncing = false;
    print('🏁 Sincronización finalizada');
  }

  /// ===============================
  /// 🔄 SINCRONIZAR ESTADOS DESDE BACKEND
  /// ===============================
  Future<void> syncStatusesFromServer(String token) async {
    try {
      print('🔄 Sincronizando estados desde servidor...');

      final response = await http.get(
        Uri.parse(_backendUrl),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        print('❌ Error obteniendo incidentes del servidor');
        return;
      }

      final List data = jsonDecode(response.body);

      for (final item in data) {
        if (item['local_id'] == null || item['status'] == null) continue;

        await LocalDB.updateIncidentStatusByLocalId(
          item['local_id'],
          item['status'],
        );
      }

      print('✅ Estados locales actualizados');
    } catch (e) {
      print('🔥 Error sincronizando estados: $e');
    }
  }

  void stop() {
    _subscription?.cancel();
  }
}
