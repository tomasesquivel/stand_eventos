import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  List<dynamic> _desafios = [];
  int _indiceActual = 0;
  bool _isLoading = true;
  String? _mensajeError;
  
  bool _bloqueoActivo = false;
  bool _exitoActivo = false; 

  bool _mostrarPista = false;
  bool _pistaRegistradaEnDB = false;

  Map<String, dynamic>? get _desafioActual =>
      (_desafios.isNotEmpty && _indiceActual < _desafios.length)
          ? _desafios[_indiceActual]
          : null;

  @override
  void initState() {
    super.initState();
    _cargarDesafios();
  }

  @override
  void dispose() {
    _respuestaCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarDesafios() async {
    try {
      final data = await supabase
          .from('desafio')
          .select('*, pista(*)')
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('orden_resolucion', ascending: true);

      if (!mounted) return;
      setState(() {
        _desafios = data;
        _indiceActual = 0;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'Error al cargar los desafíos: $e';
        _isLoading = false;
      });
    }
  }

  String? _obtenerTextoPista() {
    if (_desafioActual == null || _desafioActual!['pista'] == null) return null;
    final pistaData = _desafioActual!['pista'];

    if (pistaData is List && pistaData.isNotEmpty) {
      final texto = pistaData[0]['texto_ayuda']?.toString().trim();
      return (texto != null && texto.isNotEmpty) ? texto : null;
    } else if (pistaData is Map) {
      final texto = pistaData['texto_ayuda']?.toString().trim();
      return (texto != null && texto.isNotEmpty) ? texto : null;
    }
    return null;
  }

  Future<void> _solicitarPista() async {
    final textoPista = _obtenerTextoPista();
    if (textoPista == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay pistas configuradas para este desafío.'),
          backgroundColor: Colors.orangeAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _mostrarPista = true;
    });

    if (!_pistaRegistradaEnDB) {
      _pistaRegistradaEnDB = true;
      try {
        await supabase.from('progreso_desafio').insert({
          'id_desafio': _desafioActual!['id_desafio'],
          'solicito_pista': true,
        });
      } catch (e) {
        debugPrint('Aviso ESC06: Falta ID de participación -> $e');
      }
    }
  }

  Future<void> _verificarCodigoElementoFisico(String codigoIngresado) async {
    if (_desafioActual == null) return;

    FocusScope.of(context).unfocus();

    final String codigoLimpio = codigoIngresado.trim().toUpperCase();
    final String codigoCorrecto = _desafioActual!['respuesta_correcta'].toString().trim().toUpperCase();

    if (codigoLimpio.isEmpty || codigoLimpio != codigoCorrecto) {
      setState(() {
        _bloqueoActivo = true;
        _exitoActivo = false;
      });

      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código incorrecto. Revisa el elemento físico e intenta de nuevo.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _bloqueoActivo = false;
      _exitoActivo = true; 
    });

    HapticFeedback.heavyImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Código correcto!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1500),
      ),
    );

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    setState(() {
      _exitoActivo = false;
      _respuestaCtrl.clear();
      _mostrarPista = false;
      _pistaRegistradaEnDB = false;
      
      if (_indiceActual + 1 < _desafios.length) {
        _indiceActual++;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Misión Completada! (Pantalla final en desarrollo)'),
            backgroundColor: Colors.amberAccent,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  void _simularEscaneoQR(BuildContext context) {
    if (_desafioActual == null) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Simulador de Cámara QR', style: TextStyle(color: Colors.cyan)),
          content: const Text('Selecciona qué lectura querés simular para este elemento físico:'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _verificarCodigoElementoFisico('CODIGO_ERRONEO_SIMULADO');
              },
              child: const Text('QR Inválido', style: TextStyle(color: Colors.redAccent)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                final String qrCorrecto = _desafioActual!['respuesta_correcta'].toString();
                _verificarCodigoElementoFisico(qrCorrecto);
              },
              child: const Text('QR Válido', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experiencia;
    final int minutos = exp['tiempo_limite_minutos'] ?? 5;
    final String tiempoFormateado = '${minutos.toString().padLeft(2, '0')}:00';
    final String? textoPista = _obtenerTextoPista();

    // ESC08: Cálculos para la barra de progreso
    final int numeroDesafio = _indiceActual + 1;
    final int totalDesafios = _desafios.length;
    final double progreso = totalDesafios > 0 ? (numeroDesafio / totalDesafios) : 0.0;

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
                          'No existe un desafío configurado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: Column(
                          key: ValueKey<int>(_indiceActual),
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

                            // ESC08: Indicador textual y visual del progreso
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'DESAFÍO $numeroDesafio DE $totalDesafios',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Text(
                                    '${(progreso * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
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
                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withAlpha(25),
                                border: Border.all(color: Colors.amberAccent),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.search, color: Colors.amberAccent, size: 20),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'BUSCA LA PISTA EN EL ELEMENTO FÍSICO DEL STAND',
                                      style: TextStyle(
                                        color: Colors.amberAccent,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                border: Border.all(
                                  color: _exitoActivo 
                                      ? Colors.greenAccent 
                                      : (_bloqueoActivo ? Colors.redAccent : Colors.cyan),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_exitoActivo 
                                            ? Colors.greenAccent 
                                            : (_bloqueoActivo ? Colors.redAccent : Colors.cyan))
                                        .withAlpha(30),
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
                                        : 'Inspecciona el elemento físico señalado en el stand.',
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
                                enabled: !_exitoActivo, 
                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                decoration: InputDecoration(
                                  labelText: 'Ingresa el código del objeto físico',
                                  labelStyle: const TextStyle(color: Colors.grey),
                                  errorText: _bloqueoActivo ? 'Secuencia incorrecta.' : null,
                                  filled: true,
                                  fillColor: const Color(0xFF1A1A1A),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: _bloqueoActivo ? Colors.redAccent : Colors.white24,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderSide: const BorderSide(color: Colors.greenAccent, width: 2),
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
                                  onPressed: _exitoActivo 
                                      ? null 
                                      : () => _verificarCodigoElementoFisico(_respuestaCtrl.text),
                                  icon: const Icon(Icons.lock_open),
                                  label: const Text(
                                    'VERIFICAR CÓDIGO',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.cyan,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: Colors.green,
                                    disabledForegroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ] else if (_desafioActual!['tipo'] == 'qr') ...[
                              Center(
                                child: Column(
                                  children: [
                                    const Text(
                                      'ENCUENTRA Y ESCANEA EL QR OCULTO',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey, fontSize: 13),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 60,
                                      child: ElevatedButton.icon(
                                        onPressed: _exitoActivo ? null : () => _simularEscaneoQR(context),
                                        icon: Icon(_exitoActivo ? Icons.check_circle : Icons.qr_code_scanner, size: 28),
                                        label: Text(
                                          _exitoActivo ? 'CÓDIGO VERIFICADO' : 'ESCANEAR CÓDIGO QR',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.cyan,
                                          foregroundColor: Colors.black,
                                          disabledBackgroundColor: Colors.green,
                                          disabledForegroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            Center(
                              child: OutlinedButton.icon(
                                onPressed: _solicitarPista,
                                icon: const Icon(Icons.lightbulb_outline, color: Colors.amberAccent),
                                label: Text(
                                  _mostrarPista ? 'Pista revelada' : 'Solicitar Pista',
                                  style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.amberAccent),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ),

                            if (_mostrarPista && textoPista != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amberAccent.withAlpha(20),
                                  border: Border.all(color: Colors.amberAccent),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.amberAccent),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'PISTA DE AYUDA:',
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            textoPista,
                                            style: const TextStyle(color: Colors.white, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
    );
  }
}