import 'package:flutter/material.dart';

class PantallaMisionCompletada extends StatelessWidget {
  final Map<String, dynamic> experiencia;
  final int segundosGastados;

  const PantallaMisionCompletada({
    super.key,
    required this.experiencia,
    required this.segundosGastados,
  });

  @override
  Widget build(BuildContext context) {
    // Calculamos los minutos y segundos exactos que tardó en ganar
    final int minutos = segundosGastados ~/ 60;
    final int segundos = segundosGastados % 60;
    final String tiempoFormateado = '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    
    // Si el admin configuró un mensaje en ADM02, lo mostramos; sino, un código por defecto
    final String mensajeRecompensa = (experiencia['mensaje_recompensa_final'] != null && 
                                      experiencia['mensaje_recompensa_final'].toString().trim().isNotEmpty)
        ? experiencia['mensaje_recompensa_final'].toString()
        : 'ESC-7X9K-2024';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo verde de Sistema Descifrado
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: Colors.greenAccent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withAlpha(50), 
                      blurRadius: 40, 
                      spreadRadius: 10
                    ),
                  ]
                ),
                child: const Icon(Icons.check, color: Colors.greenAccent, size: 80),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'MISIÓN COMPLETADA', 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
              ),
              const SizedBox(height: 10),
              const Text('SISTEMA DESCIFRADO EXITOSAMENTE', style: TextStyle(color: Colors.greenAccent, fontSize: 14, letterSpacing: 1.5)),
              
              const SizedBox(height: 40),
              const Text('ESTADÍSTICAS DE OPERARIO', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                'Tiempo Total: $tiempoFormateado min', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
              Text(
                'Misión: ${experiencia['nombre'].toString().toUpperCase()}', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
              
              const SizedBox(height: 30),
              const Text(
                '¡Felicidades!', 
                style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              const Text(
                'Presenta este código en el stand para reclamar tu recompensa física:', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, height: 1.5)
              ),
              const SizedBox(height: 15),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withAlpha(20),
                  border: Border.all(color: Colors.greenAccent),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mensajeRecompensa,
                  style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    // Limpia la pila de navegación y vuelve al catálogo/inicio
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                  ),
                  child: const Text('VOLVER AL CATÁLOGO', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}