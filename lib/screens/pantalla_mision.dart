import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaMision extends StatefulWidget {
  const PantallaMision({super.key});

  @override
  State<PantallaMision> createState() => _PantallaMisionState();
}

class _PantallaMisionState extends State<PantallaMision> {
  final supabase = Supabase.instance.client;
  
  Map<String, dynamic>? _experienciaData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatosMision();
  }

  Future<void> _cargarDatosMision() async {
    try {
      // Traemos la experiencia activa desde la base de datos
      final data = await supabase
          .from('experiencia')
          .select()
          .eq('activa', true)
          .limit(1)
          .single();

      setState(() {
        _experienciaData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar la misión: $e';
        _isLoading = false;
      });
    }
  }

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
      // Mostramos un loader mientras espera la base de datos
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)))
              : Padding(
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

                      // Inyección dinámica del Nombre
                      Text(
                        _experienciaData!['nombre'].toString().toUpperCase(),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                      ),
                      const SizedBox(height: 20),

                      // VIS04: Inyección dinámica del Tiempo Límite
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
                                Text(
                                  '${_experienciaData!['tiempo_limite_minutos']} MINUTOS', 
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // VIS03: Inyección dinámica de las Instrucciones
                      const Text(
                        'OBJETIVO PRINCIPAL:',
                        style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _experienciaData!['descripcion'].toString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
                      ),
                      
                      const Spacer(),

                      // Botón de inicio
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