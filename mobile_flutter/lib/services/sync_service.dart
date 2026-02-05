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

    // Cargar credenciales al arrancar
    await AuthService.init();

    _subscription =
        _connectivity.onConnectivityChanged.listen((results) async {
          print('📡 Conectividad detectada: $results');
          // Si hay conexión (móvil o wifi), intentamos sincronizar
          if (results.contains(ConnectivityResult.mobile) ||
              results.contains(ConnectivityResult.wifi)) {
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
      // 1. OBTENER TOKEN FRESCO (Vital por el cambio de contraseña)
      await AuthService.init();
      final token = AuthService.token;

      if (token == null || token.isEmpty) {
        print('⚠️ Cancelado: No hay token guardado. Usuario debe loguearse.');
        _isSyncing = false;
        return;
      }

      // Debug: Verificamos si estamos enviando token (solo primeros 10 chars)
      print('🔑 Usando Token: ${token.substring(0, 10)}...');

      // 2. BUSCAR PENDIENTES
      final pending = await LocalDB.getPendingIncidents();
      print('📦 Incidentes en cola: ${pending.length}');

      if (pending.isEmpty) {
        _isSyncing = false;
        return;
      }

      // 3. ENVIAR UNO POR UNO
      for (final incident in pending) {
        try {
          final payload = {
            'tipo': incident['tipo'],
            'descripcion': incident['descripcion'],
            'latitude': incident['lat'],
            'longitude': incident['lng'],
            'smart_score': incident['smart_score'],
            'local_id': incident['local_id'],
            // Fecha opcional, el servidor pone la suya si no se envía
          };

          print('➡️ Enviando ID Local ${incident['local_id']}...');

          final response = await http.post(
            Uri.parse(_backendUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token', // AQUÍ VA LA LLAVE
            },
            body: jsonEncode(payload),
          );

          print('🔙 Respuesta Servidor: ${response.statusCode}');

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
            print('⛔ TOKEN VENCIDO O INCORRECTO. Se requiere Relogin.');
            // Aquí podrías forzar cierre de sesión si quisieras
          } else {
            // OTROS ERRORES
            print('❌ Error del servidor: ${response.body}');
          }
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
  }
}