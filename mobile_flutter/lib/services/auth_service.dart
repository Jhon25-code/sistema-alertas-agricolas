import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaas/config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static String? _token;

  /// Token en memoria
  static String? get token => _token;

  /// Inicializa auth (login silencioso)
  static Future<void> init() async {
    if (_token != null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    // Si ya hay token guardado → usarlo
    if (savedToken != null) {
      _token = savedToken;
      print("🔐 TOKEN RECUPERADO DE STORAGE");
      return;
    }

    // Login automático
    final url = "${ApiConfig.baseUrl}/auth/login";

    final response = await http.post(
      Uri.parse(url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": "trabajador",
        "password": "123456",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data["token"];

      await prefs.setString(_tokenKey, _token!);

      print("🔐 TOKEN OBTENIDO Y GUARDADO");
    } else {
      print("❌ ERROR LOGIN: ${response.body}");
    }
  }

  /// Headers listos para backend
  static Future<Map<String, String>> authHeaders() async {
    if (_token == null) {
      await init();
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_token",
    };
  }

  /// Cerrar sesión (si algún día lo necesitas)
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
  }
}
