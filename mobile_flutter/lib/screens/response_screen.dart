import 'package:flutter/material.dart';

class ResponseScreen extends StatelessWidget {
  const ResponseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Response Screen'),
      ),
      body: const Center(
        child: Text('Contenido de la pantalla de respuesta'),
      ),
    );
  }
}
