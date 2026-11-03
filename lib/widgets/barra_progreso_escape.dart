import 'package:flutter/material.dart';

class BarraProgresoEscape extends StatelessWidget {
  final int desafioActual;
  final int totalDesafios;

  const BarraProgresoEscape({
    super.key,
    required this.desafioActual,
    required this.totalDesafios,
  });

  @override
  Widget build(BuildContext context) {
    final double progreso = totalDesafios > 0 ? (desafioActual / totalDesafios) : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'DESAFÍO $desafioActual DE $totalDesafios',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Text(
                '${(progreso * 100).toInt()}%',
                style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progreso,
          backgroundColor: Colors.white24,
          color: Colors.cyanAccent,
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }
}