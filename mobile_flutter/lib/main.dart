import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/incident_type_screen.dart';
import 'screens/report_screen.dart';
import 'screens/pending_sync_screen.dart';

void main() {
  runApp(const SiaasApp());
}

class SiaasApp extends StatelessWidget {
  const SiaasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SIAAS',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1B5E20),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/incident_type': (_) => const IncidentTypeScreen(),
        '/report': (_) => const ReportScreen(),
        '/pending': (_) => const PendingSyncScreen(),
      },
    );
  }
}
