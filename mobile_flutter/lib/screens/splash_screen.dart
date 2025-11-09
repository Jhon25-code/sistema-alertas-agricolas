import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F2F1), Color(0xFFF1F8E9)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_siaas.png', height: 120, errorBuilder: (_, __, ___)=> const Icon(Icons.grass, size: 120)),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16), backgroundColor: const Color(0xFF66BB6A), foregroundColor: Colors.black),
                onPressed: () => Navigator.pushReplacementNamed(context, '/incident_type'),
                child: const Text('REPORTAR INCIDENTE'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
