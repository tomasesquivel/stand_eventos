import 'package:flutter/material.dart';
import '../utils/sesion_local.dart';

class PantallaMisionCompletada extends StatelessWidget {
  final Map<String, dynamic> experiencia;
  final int segundosGastados;
  final int puntajeTotal;

  const PantallaMisionCompletada({
    super.key,
    required this.experiencia,
    required this.segundosGastados,
    required this.puntajeTotal,
  });

  @override
  Widget build(BuildContext context) {
    SesionLocal.misionesCompletadas.add(experiencia['id_experiencia'].toString());
    
    final int minutos = segundosGastados ~/ 60;
    final int segundos = segundosGastados % 60;
    final String tiempoFormateado = '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    
    final String mensajeRecompensa = (experiencia['mensaje_recompensa_final'] != null && 
                                      experiencia['mensaje_recompensa_final'].toString().trim().isNotEmpty)
        ? experiencia['mensaje_recompensa_final'].toString()
        : 'ESC-7X9K-2024';

    final String nombreMision = experiencia['nombre'].toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 35, horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.amberAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amberAccent.withAlpha(40), 
                      blurRadius: 30, 
                      spreadRadius: 5
                    ),
                  ]
                ),
                child: Column(
                  children: [
                    const Text(
                      'INSIGNIA DESBLOQUEADA',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                    const SizedBox(height: 20),
                    const Icon(Icons.military_tech, color: Colors.amberAccent, size: 100),
                    const SizedBox(height: 20),
                    Text(
                      nombreMision, 
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              Text(
                'Puntaje Obtenido: $puntajeTotal pts', 
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 8),
              Text(
                'Tiempo Total: $tiempoFormateado min', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
              
              const SizedBox(height: 40),
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
                    Navigator.pop(context);
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