import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaas/config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
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
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      print("🔐 TOKEN RECUPERADO DE STORAGE");
      return;
    }

    print("🔑 No hay token. Haciendo login automático (DEMO)...");
    await _autoLoginDemo();
  }

  static Future<void> _autoLoginDemo() async {
    final ok = await _doLoginAndStore(
      username: _demoUser,
      password: _demoPass,
      allowMultiplePayloads: true,
    );

    if (!ok) {
      print("❌ ERROR LOGIN AUTOMÁTICO");
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
    print("➡️ LOGIN URL: $url");
    print("👤 user=$username");

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
        print("📤 LOGIN payload: ${jsonEncode(payload)}");

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

        print("🔙 LOGIN status: ${response.statusCode}");
        print("🔙 LOGIN body: ${response.body}");

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final t = data["token"];

          if (t is String && t.isNotEmpty) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_tokenKey, t);
            _token = t;
            print("✅ LOGIN OK - TOKEN GUARDADO");
            return true;
          } else {
            print("❌ Login OK pero no llegó token");
            return false;
          }
        }

        // Si el backend responde 401, probamos siguiente formato
      }

      return false;
    } catch (e) {
      print("🔥 ERROR LOGIN: $e");
      return false;
    }
  }

  static Future<Map<String, String>> authHeaders() async {
    if (_token == null) await init();

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_token != null && _token!.isNotEmpty) "Authorization": "Bearer $_token",
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    print("🔓 Token eliminado");
  }
}
