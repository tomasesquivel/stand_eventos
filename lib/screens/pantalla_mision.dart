import 'package:flutter/material.dart';

class PantallaMision extends StatelessWidget {
  const PantallaMision({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CONEXIÓN ESTABLECIDA',
          style: TextStyle(color: Colors.cyanAccent, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyan),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan.withAlpha(50),
                border: Border.all(color: Colors.cyan),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'ESTADO: STAND ACTIVO', 
                style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),

            const Text(
              'OPERACIÓN: NÚCLEO',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 20),

            // VIS04: Indicador de duración del desafío
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 28),
                  SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TIEMPO LÍMITE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('15 MINUTOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // VIS03: Instrucciones de la base de datos
            const Text(
              'OBJETIVO PRINCIPAL:',
              style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              'El sistema principal ha sido bloqueado. Tu misión es buscar las pistas físicas escondidas en este stand, resolver los acertijos y recuperar la contraseña de anulación antes de que el servidor se formatee por completo.',
              style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            
            const Spacer(),

            // VIS03: Botón de inicio explícito
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('⏳ Cronómetro iniciado. ¡Buena suerte!'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'COMENZAR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}