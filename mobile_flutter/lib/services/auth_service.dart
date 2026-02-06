import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:siaas/config/api_config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static String? _token;

  /// Token en memoria
  static String? get token => _token;

  /// ===============================
  /// INIT: SOLO carga token guardado
  /// (NO hace login automático)
  /// ===============================
  static Future<void> init() async {
    if (_token != null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_tokenKey);

    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;
      print("🔐 TOKEN RECUPERADO DE STORAGE");
    } else {
      print("⚠️ No hay token guardado");
    }
  }

  /// ===============================
  /// LOGIN EXPLÍCITO (usuario/password)
  /// ===============================
  static Future<bool> login({
    required String username,
    required String password,
  }) async {
    final url = "${ApiConfig.baseUrl}/auth/login";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data["token"];

        if (token == null || token.isEmpty) {
          print("❌ Login sin token válido");
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);

        _token = token;

        print("🔐 LOGIN OK - TOKEN GUARDADO");
        return true;
      } else {
        print("❌ ERROR LOGIN: ${response.body}");
        return false;
      }
    } catch (e) {
      print("🔥 ERROR LOGIN EXCEPTION: $e");
      return false;
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
      "Authorization": _token != null ? "Bearer $_token" : "",
    };
  }

  /// ===============================
  /// Cerrar sesión
  /// ===============================
  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    _token = null;
    print("🔓 Sesión cerrada, token eliminado");
  }
}
