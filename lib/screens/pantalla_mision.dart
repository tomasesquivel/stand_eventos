import 'package:flutter/material.dart';

class PantallaMision extends StatefulWidget {
  // Ahora la pantalla exige que le pasen los datos de la experiencia al abrirse
  final Map<String, dynamic> experiencia;
  
  const PantallaMision({super.key, required this.experiencia});

  @override
  State<PantallaMision> createState() => _PantallaMisionState();
}

class _PantallaMisionState extends State<PantallaMision> {
  @override
  Widget build(BuildContext context) {
    // Usamos widget.experiencia para leer los datos que vinieron por parámetro
    final exp = widget.experiencia;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CONEXIÓN ESTABLECIDA', style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
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
              child: const Text('ESTADO: STAND ACTIVO', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            Text(
              exp['nombre'].toString().toUpperCase(),
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: Colors.white24),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.amberAccent, size: 28),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('TIEMPO LÍMITE', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text('${exp['tiempo_limite_minutos']} MINUTOS', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text('OBJETIVO PRINCIPAL:', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            Text(
              exp['descripcion'].toString(),
              style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
            ),
            
            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('⏳ Cronómetro iniciado. ¡Buena suerte!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: const Text('COMENZAR', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}