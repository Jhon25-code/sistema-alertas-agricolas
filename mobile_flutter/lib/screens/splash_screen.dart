import 'package:flutter/material.dart';
import '../services/sync_service.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _authChecked = false;

  @override
  void initState() {
    super.initState();

    // ✅ INICIAR SINCRONIZACIÓN OFFLINE → ONLINE
    SyncService().startSyncListener();
    debugPrint('✅ SyncService iniciado desde SplashScreen');

    // ✅ Verificar token guardado (sin login automático)
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await AuthService.init();
    final token = AuthService.token;

    if (!mounted) return;

    setState(() {
      _authChecked = true;
    });

    if (token == null || token.isEmpty) {
      debugPrint('⚠️ No hay token guardado → redirigiendo a /login');
      // No obligamos navegación inmediata si quieres que el usuario vea el splash,
      // pero lo dejamos listo para que al tocar el botón vaya a login.
      // Si deseas redirigir automáticamente, descomenta lo siguiente:
      // Navigator.pushReplacementNamed(context, '/login');
    } else {
      debugPrint('🔐 Token detectado en storage (len=${token.length})');
    }
  }

  @override
  void dispose() {
    // ✅ Detener listener al cerrar la app
    SyncService().stop();
    debugPrint('🛑 SyncService detenido');
    super.dispose();
  }

  void _goNext() async {
    // Asegurar que ya se revisó auth
    if (!_authChecked) {
      await _checkAuth();
      if (!mounted) return;
    }

    final token = AuthService.token;
    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      Navigator.pushReplacementNamed(context, '/incident_type');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/fondo_inicio.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                "assets/images/logo_siaas.png",
                width: 200,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _goNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
                child: const Text(
                  "REPORTAR INCIDENTE",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
