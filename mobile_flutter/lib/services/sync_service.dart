import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart'; // Para vibración nativa

import 'local_db.dart';
import 'package:siaas/config/api_config.dart';
import 'auth_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _isSyncing = false;

  /// URL backend
  static final String _backendUrl = "${ApiConfig.baseUrl}/incidents";

  /// ===============================
  /// INICIAR ESCUCHA DE CONECTIVIDAD
  /// ===============================
  Future<void> startSyncListener() async {
    print('🔄 SyncService ACTIVADO');

    // Evitar duplicar listeners si se llama más de una vez
    await _subscription?.cancel();

    // ✅ IMPORTANTE:
    // AuthService.init() aquí debe SOLO cargar token guardado (NO hacer /auth/login).
    await AuthService.init();

    // ✅ CHEQUEO INICIAL: connectivity_plus no siempre emite estado inicial
    final initial = await _connectivity.checkConnectivity();
    print('📡 Conectividad inicial: $initial');
    final hasInitialConnection = !initial.contains(ConnectivityResult.none);
    if (hasInitialConnection) {
      await syncNow();
    }

    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      print('📡 Conectividad detectada: $results');

      // Si NO está en none, hay alguna conexión disponible
      final hasConnection = !results.contains(ConnectivityResult.none);

      if (hasConnection) {
        await syncNow();
      }
    });
  }

  /// ===============================
  /// SINCRONIZACIÓN PRINCIPAL
  /// ===============================
  Future<void> syncNow() async {
    if (_isSyncing) return; // Evitar doble ejecución

    _isSyncing = true;
    print('🚀 Iniciando proceso de sincronización...');

    try {
      // ✅ NO volver a llamar AuthService.init() aquí, porque en tu caso
      // estaba intentando /auth/login y fallando con "Credenciales incorrectas".
      // Solo usamos el token ya guardado por el login manual.
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        print('⚠️ Cancelado: No hay token guardado. Usuario debe loguearse.');
        return;
      }

      // Debug seguro: no revienta si el token es corto
      final preview = token.length >= 10 ? token.substring(0, 10) : token;
      print('🔑 Usando Token: $preview... (len=${token.length})');

      // 2. BUSCAR PENDIENTES
      final pending = await LocalDB.getPendingIncidents();
      print('📦 Incidentes en cola: ${pending.length}');

      if (pending.isEmpty) {
        return;
      }

      // 3. ENVIAR UNO POR UNO
      for (final incident in pending) {
        try {
          // ✅ Si no hay coordenadas, no enviamos (en tus logs estaban null)
          final lat = incident['lat'];
          final lng = incident['lng'];

          if (lat == null || lng == null) {
            print(
              '⚠️ Incidente ${incident['local_id']} sin coordenadas (lat/lng null). No se envía.',
            );
            continue;
          }

          final payload = {
            'tipo': incident['tipo'],
            'descripcion': incident['descripcion'],
            'latitude': lat,
            'longitude': lng,
            'smart_score': incident['smart_score'],
            'local_id': incident['local_id'],
            // Fecha opcional, el servidor pone la suya si no se envía
          };

          print('➡️ Enviando ID Local ${incident['local_id']}...');
          print('📤 Payload: ${jsonEncode(payload)}');
          print('➡️ URL: $_backendUrl');

          final response = await http
              .post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token', // AQUÍ VA LA LLAVE
            },
            body: jsonEncode(payload),
          )
              .timeout(const Duration(seconds: 20));

          print('🔙 Respuesta Servidor: ${response.statusCode}');
          print('🔙 Body: ${response.body}');

          if (response.statusCode == 200 || response.statusCode == 201) {
            // ✅ ÉXITO
            await LocalDB.updateIncidentStatusByLocalId(
              incident['local_id'],
              'ENVIADO', // Cambiamos estado local para que se ponga verde
            );

            await LocalDB.markAsSynced(incident['id']);
            print('✅ ¡Sincronizado con éxito!');

            // Feedback Háptico (Latido)
            await HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 100));
            await HapticFeedback.heavyImpact();
          } else if (response.statusCode == 401) {
            // ⛔ ERROR DE TOKEN
            print(
              '⛔ TOKEN VENCIDO / NO PROPORCIONADO / INCORRECTO. Se requiere Relogin.',
            );
          } else {
            // OTROS ERRORES
            print('❌ Error del servidor: ${response.body}');
          }
        } on TimeoutException catch (_) {
          print('⏱️ Timeout enviando incidente (posible red lenta o backend dormido).');
        } catch (e) {
          print('🔥 Error de red al enviar incidente: $e');
        }
      }
    } catch (e) {
      print('🔥 Error general en SyncService: $e');
    } finally {
      _isSyncing = false;
      print('🏁 Sincronización finalizada.');
    }
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
