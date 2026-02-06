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

  /// Token en memoria
  static String? get token => _token;

  /// ===============================
  /// INIT: carga token o hace login directo
  /// ===============================
  static Future<void> init() async {
    if (_token != null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    // 1️⃣ Si ya hay token guardado → usarlo
    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      print("🔐 TOKEN RECUPERADO DE STORAGE");
      return;
    }

    // 2️⃣ NO hay token → login automático con credenciales fijas
    print("🔑 No hay token. Haciendo login automático (DEMO)...");

    final url = "${ApiConfig.baseUrl}/auth/login";

    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "username": _demoUser,
        "password": _demoPass,
      }),
    );

    print("🔙 LOGIN status: ${response.statusCode}");
    print("🔙 LOGIN body: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data["token"];

      if (token is String && token.isNotEmpty) {
        _token = token;
        await prefs.setString(_tokenKey, token);
        print("✅ LOGIN AUTOMÁTICO OK - TOKEN GUARDADO");
      } else {
        print("❌ LOGIN OK pero no llegó token");
      }
    } else {
      print("❌ ERROR LOGIN AUTOMÁTICO");
    }
  }

  /// ===============================
  /// Headers listos para backend
  /// ===============================
  static Future<Map<String, String>> authHeaders() async {
    if (_token == null) {
      await init();
    }

    return {
      "Content-Type": "application/json",
      "Accept": "application/json",
      if (_token != null) "Authorization": "Bearer $_token",
    };
  }

  /// ===============================
  /// Cerrar sesión (opcional)
  /// ===============================
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    print("🔓 Token eliminado");
  }
}
