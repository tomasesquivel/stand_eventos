import 'package:flutter/material.dart';

class PantallaTiempoAgotado extends StatelessWidget {
  final Map<String, dynamic> experiencia;

  const PantallaTiempoAgotado({super.key, required this.experiencia});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Círculo rojo de Sistema Bloqueado
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A1A1A),
                  border: Border.all(color: Colors.redAccent, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withAlpha(50), 
                      blurRadius: 40, 
                      spreadRadius: 10
                    ),
                  ]
                ),
                child: const Icon(Icons.close, color: Colors.redAccent, size: 80),
              ),
              const SizedBox(height: 40),
              
              const Text(
                'TIEMPO AGOTADO', 
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)
              ),
              const SizedBox(height: 10),
              const Text('SISTEMA BLOQUEADO', style: TextStyle(color: Colors.redAccent, fontSize: 16, letterSpacing: 1.5)),
              const SizedBox(height: 5),
              const Text('SECUENCIA FALLIDA', style: TextStyle(color: Colors.redAccent, fontSize: 16, letterSpacing: 1.5)),
              
              const SizedBox(height: 40),
              const Text('ESTADÍSTICAS DE OPERARIO', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              Text(
                'Tiempo Límite: ${experiencia['tiempo_limite_minutos']}:00 min', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
              Text(
                'Misión: ${experiencia['nombre'].toString().toUpperCase()}', 
                style: const TextStyle(color: Colors.white, fontSize: 16)
              ),
              
              const SizedBox(height: 30),
              const Text(
                'PROTOCOLO INCOMPLETO\nLa misión ha fallado. No te rindas, operario. Puedes volver a intentarlo en el stand físico.', 
                textAlign: TextAlign.center, 
                style: TextStyle(color: Colors.grey, height: 1.5)
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton(
                  onPressed: () {
                    // Cierra todas las pantallas apiladas y vuelve a la principal / catálogo
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