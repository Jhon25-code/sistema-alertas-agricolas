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

  // ✅ connectivity_plus v6+: Stream emite List<ConnectivityResult>
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isSyncing = false;
  bool _authInvalid = false; // evita reintentos infinitos si token es inválido

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

    // ✅ Chequeo inicial v6+: devuelve List<ConnectivityResult>
    final initial = await _connectivity.checkConnectivity();
    print('📡 Conectividad inicial: $initial');

    final hasInitialConnection = !initial.contains(ConnectivityResult.none);
    if (hasInitialConnection) {
      await syncNow();
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
          (List<ConnectivityResult> results) async {
        print('📡 Conectividad detectada: $results');

        final hasConnection = !results.contains(ConnectivityResult.none);
        if (hasConnection) {
          await syncNow();
        }
      },
    );
  }

  // =========================================================
  // SINCRONIZACIÓN PRINCIPAL
  // =========================================================
  Future<void> syncNow() async {
    if (_isSyncing) return;

    if (_authInvalid) {
      print('⛔ Sync bloqueado: token inválido. Requiere relogin.');
      return;
    }

    _isSyncing = true;
    print('🚀 Iniciando sincronización...');

    try {
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        print('⚠️ No hay token. Se omite sync hasta que el usuario inicie sesión.');
        return;
      }

      final preview = token.length > 10 ? token.substring(0, 10) : token;
      print('🔑 Token activo: $preview... (len=${token.length})');

      final pending = await LocalDB.getPendingIncidents();
      print('📦 Incidentes pendientes: ${pending.length}');
      if (pending.isEmpty) return;

      for (final incident in pending) {
        try {
          final latRaw = incident['lat'];
          final lngRaw = incident['lng'];

          if (latRaw == null || lngRaw == null) {
            print('⚠️ Incidente ${incident['local_id']} sin GPS (null). Omitido.');
            continue;
          }

          // Convertir a double si viene como string/int
          final lat = (latRaw is num) ? latRaw.toDouble() : double.tryParse(latRaw.toString());
          final lng = (lngRaw is num) ? lngRaw.toDouble() : double.tryParse(lngRaw.toString());

          if (lat == null || lng == null) {
            print('⚠️ Incidente ${incident['local_id']} GPS inválido. Omitido.');
            continue;
          }

          final payload = {
            'tipo': incident['tipo'],
            'descripcion': incident['descripcion'],
            'latitude': lat,
            'longitude': lng,
            'smart_score': incident['smart_score'],
          };

          print('📤 Enviando incidente ${incident['local_id']} -> $_backendUrl');
          print('📤 Payload: ${jsonEncode(payload)}');

          final response = await http
              .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
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
            _authInvalid = true;
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

  /// Llama a esto después de un login exitoso si quieres re-habilitar sync inmediatamente.
  void resetAuthBlock() {
    _authInvalid = false;
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
