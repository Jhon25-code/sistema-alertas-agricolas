import 'package:flutter/material.dart';

import 'package:siaas/screens/splash_screen.dart';
import 'package:siaas/screens/incident_type_screen.dart';
import 'package:siaas/screens/report_screen.dart';
import 'package:siaas/screens/pending_sync_screen.dart';
import 'package:siaas/screens/response_screen.dart';

// 🔐 Auth
import 'package:siaas/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Inicializa auth (solo carga token o auto-login demo según tu AuthService)
  await AuthService.init();

  // 🔄 SyncService se inicia en SplashScreen (evitamos duplicar listeners)
  runApp(const SiaasApp());
}

class SiaasApp extends StatelessWidget {
  const SiaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "SIAAS",

      // Pantalla inicial
      initialRoute: '/',

      routes: {
        '/': (context) => const SplashScreen(),
        '/incident_type': (context) => const IncidentTypeScreen(),
        '/report': (context) => const ReportScreen(),
        '/pending': (context) => const PendingSyncScreen(),
        '/response': (context) => const ResponseScreen(),
      },
    );
  }
}
