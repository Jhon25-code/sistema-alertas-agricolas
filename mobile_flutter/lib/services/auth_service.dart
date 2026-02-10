import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaas/config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';

  // ✅ key extra para compatibilidad con ReportScreen / ReportService
  static const _tokenKeyCompat = 'token';

  static String? _token;

  /// 👤 CREDENCIALES FIJAS (DEMO)
  static const String _demoUser = 'trabajador';
  static const String _demoPass = '123456';

  static String? get token => _token;

  /// ===============================
  /// INIT: carga token o hace login demo
  /// ===============================
  static Future<void> init() async {
    if (_token != null) return;

    final prefs = await SharedPreferences.getInstance();

    // ✅ primero intenta el token principal
    final savedToken = prefs.getString(_tokenKey);

    // ✅ fallback: compat (por si antes guardaste como "token")
    final savedCompat = prefs.getString(_tokenKeyCompat);

    final candidate = (savedToken != null && savedToken.isNotEmpty)
        ? savedToken
        : (savedCompat != null && savedCompat.isNotEmpty ? savedCompat : null);

    if (candidate != null && candidate.isNotEmpty) {
      _token = candidate;

      // ✅ asegura que ambas keys queden sincronizadas
      await prefs.setString(_tokenKey, candidate);
      await prefs.setString(_tokenKeyCompat, candidate);

      debugPrint("🔐 TOKEN RECUPERADO DE STORAGE");
      return;
    }

    debugPrint("🔑 No hay token. Haciendo login automático (DEMO)...");
    await _autoLoginDemo();
  }

  static Future<void> _autoLoginDemo() async {
    final ok = await _doLoginAndStore(
      username: _demoUser,
      password: _demoPass,
      allowMultiplePayloads: true,
    );

    if (!ok) {
      debugPrint("❌ ERROR LOGIN AUTOMÁTICO");
    }
  }

  /// (Opcional) Login manual si algún día lo reactivas
  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    return _doLoginAndStore(
      username: username.trim(),
      password: password.trim(),
      allowMultiplePayloads: true,
    );
  }

  static Future<bool> _doLoginAndStore({
    required String username,
    required String password,
    required bool allowMultiplePayloads,
  }) async {
    if (username.isEmpty || password.isEmpty) return false;

    final url = "${ApiConfig.baseUrl}/auth/login";
    debugPrint("➡️ LOGIN URL: $url");
    debugPrint("👤 user=$username");

    // ✅ Probar varios formatos de payload (por compatibilidad con backend)
    final attempts = <Map<String, dynamic>>[
      {"username": username, "password": password},
      {"usuario": username, "password": password},
      {"username": username, "contrasena": password},
      {"usuario": username, "contrasena": password},
      {"email": username, "password": password},
    ];

    try {
      for (final payload in attempts) {
        debugPrint("📤 LOGIN payload: ${jsonEncode(payload)}");

        final response = await http
            .post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode(payload),
        )
            .timeout(const Duration(seconds: 20));

        debugPrint("🔙 LOGIN status: ${response.statusCode}");
        debugPrint("🔙 LOGIN body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final t = data["token"];

          if (t is String && t.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();

            // ✅ guarda en ambas keys para compatibilidad total
            await prefs.setString(_tokenKey, t);
            await prefs.setString(_tokenKeyCompat, t);

            _token = t;
            debugPrint("✅ LOGIN OK - TOKEN GUARDADO");
            return true;
          } else {
            debugPrint("❌ Login OK pero no llegó token");
            return false;
          }
        }

        // Si el backend responde 401, probamos siguiente formato
      }

      return false;
    } catch (e) {
      debugPrint("🔥 ERROR LOGIN: $e");
      return false;
    }
  }

  static Future<Map<String, String>> authHeaders() async {
    if (_token == null) await init();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_token != null && _token!.isNotEmpty)
        "Authorization": "Bearer $_token",
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenKeyCompat);
    _token = null;
    debugPrint("🔓 Token eliminado");
  }
}
