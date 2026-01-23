import 'package:flutter/material.dart';

import 'package:siaas/screens/splash_screen.dart';
import 'package:siaas/screens/incident_type_screen.dart';
import 'package:siaas/screens/report_screen.dart';
import 'package:siaas/screens/pending_sync_screen.dart';
import 'package:siaas/screens/response_screen.dart';

// 🔐 Auth y Sync
import 'package:siaas/services/auth_service.dart';
import 'package:siaas/services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 LOGIN AUTOMÁTICO (NUEVO - CLAVE)
  await AuthService.init();

  // 🔄 SINCRONIZACIÓN (YA EXISTÍA)
  SyncService().startSyncListener();

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
