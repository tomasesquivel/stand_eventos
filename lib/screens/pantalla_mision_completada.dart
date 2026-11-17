import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _copiarCodigoRecompensa(BuildContext context, String codigo) {
    Clipboard.setData(ClipboardData(text: codigo));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Código de recompensa copiado al portapapeles'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SesionLocal.misionesCompletadas.add(experiencia['id_experiencia'].toString());

    final int minutos = segundosGastados ~/ 60;
    final int segundos = segundosGastados % 60;
    final String tiempoFormateado =
        '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
    final String tiempoHablado = '$minutos minutos y $segundos segundos';

    final String mensajeRecompensa = (experiencia['mensaje_recompensa_final'] != null &&
            experiencia['mensaje_recompensa_final'].toString().trim().isNotEmpty)
        ? experiencia['mensaje_recompensa_final'].toString().trim()
        : 'ESC-7X9K-2024';

    final String nombreMision = experiencia['nombre'].toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  label: 'Misión completada. Insignia desbloqueada: $nombreMision',
                  child: Container(
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
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'INSIGNIA DESBLOQUEADA',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const ExcludeSemantics(
                          child: Icon(Icons.military_tech, color: Colors.amberAccent, size: 100),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          nombreMision,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                Semantics(
                  label: 'Puntaje obtenido: $puntajeTotal puntos',
                  child: Text(
                    'Puntaje Obtenido: $puntajeTotal pts',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Tiempo empleado: $tiempoHablado',
                  child: Text(
                    'Tiempo Empleado: $tiempoFormateado',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),

                const SizedBox(height: 36),
                const Text(
                  '¡Misión Superada!',
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Presenta este código en el stand para reclamar tu recompensa física:',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 16),

                // CORRECCIÓN USABILIDAD: Tarjeta de código con botón para copiar al portapapeles
                Semantics(
                  button: true,
                  label: 'Código de recompensa: $mensajeRecompensa. Toca para copiar al portapapeles',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copiarCodigoRecompensa(context, mensajeRecompensa),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withAlpha(20),
                        border: Border.all(color: Colors.greenAccent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              mensajeRecompensa,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Tooltip(
                            message: 'Copiar código',
                            child: Icon(Icons.copy, color: Colors.greenAccent, size: 20),
                          ),
                        ],
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('VOLVER AL CATÁLOGO', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}