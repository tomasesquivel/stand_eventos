import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaJuego extends StatefulWidget {
  final Map<String, dynamic> experiencia;

  const PantallaJuego({super.key, required this.experiencia});

  @override
  State<PantallaJuego> createState() => _PantallaJuegoState();
}

class _PantallaJuegoState extends State<PantallaJuego> {
  final supabase = Supabase.instance.client;
  final TextEditingController _respuestaCtrl = TextEditingController();

  Map<String, dynamic>? _desafioActual;
  bool _isLoading = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarDesafioInicial();
  }

  @override
  void dispose() {
    _respuestaCtrl.dispose();
    super.dispose();
  }

  
  Future<void> _cargarDesafioInicial() async {
    try {
      final data = await supabase
          .from('desafio')
          .select('*, pista(*)')
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .eq('orden_resolucion', 1)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _desafioActual = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'Error al cargar el desafío inicial: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experiencia;
    final int minutos = exp['tiempo_limite_minutos'] ?? 5;
    final String tiempoFormateado = '${minutos.toString().padLeft(2, '0')}:00';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
              label: const Text(
                'ABORTAR',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.cyanAccent, size: 10),
                const SizedBox(width: 6),
                Text(
                  'TIEMPO: $tiempoFormateado',
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _mensajeError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _mensajeError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              : _desafioActual == null
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Text(
                          'No existe un desafío inicial (Orden 1) configurado para esta experiencia.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp['nombre'].toString().toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'DESAFÍO #${_desafioActual!['orden_resolucion']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

  
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              border: Border.all(color: Colors.cyan, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.cyan.withAlpha(30),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESCRIPCIÓN DEL ACERTIJO',
                                  style: TextStyle(
                                    color: Colors.cyanAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  (_desafioActual!['descripcion'] != null &&
                                          _desafioActual!['descripcion'].toString().trim().isNotEmpty)
                                      ? _desafioActual!['descripcion'].toString()
                                      : 'Resuelve el primer acertijo oculto en los elementos físicos del stand.',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                         
                          if (_desafioActual!['tipo'] == 'texto') ...[
                            TextField(
                              controller: _respuestaCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 18),
                              decoration: InputDecoration(
                                labelText: 'Ingresa la palabra clave',
                                labelStyle: const TextStyle(color: Colors.grey),
                                filled: true,
                                fillColor: const Color(0xFF1A1A1A),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white24),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.cyanAccent, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Respuesta enviada para verificación...'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.lock_open),
                                label: const Text(
                                  'VERIFICAR CÓDIGO',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyan,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ] else if (_desafioActual!['tipo'] == 'qr') ...[
                            Center(
                              child: Column(
                                children: [
                                  const Text(
                                    'ESTE DESAFÍO REQUIERE ESCANEAR UN QR EN EL STAND',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 60,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Cámara activada para escanear QR...'),
                                            duration: Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.qr_code_scanner, size: 28),
                                      label: const Text(
                                        'ESCANEAR CÓDIGO QR',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyan,
                                        foregroundColor: Colors.black,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }
}