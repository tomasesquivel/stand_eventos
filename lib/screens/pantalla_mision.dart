import 'package:flutter/material.dart';

class PantallaMision extends StatelessWidget {
  const PantallaMision({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Misión Detectada'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text(
          '¡Conexión establecida con el Stand!',
          style: TextStyle(color: Colors.greenAccent, fontSize: 20),
        ),
      ),
    );
  }
}