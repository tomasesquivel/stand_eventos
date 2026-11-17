import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_tiempo_agotado.dart';
import 'pantalla_mision_completada.dart';
import '../widgets/barra_progreso_escape.dart';
import '../widgets/tarjeta_pista_ayuda.dart';
import 'pantalla_escaner_qr.dart';
import '../utils/sesion_local.dart';

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
  bool _alertaUnMinutoMostrada = false;

  int _puntajeAcumulado = 0;

  Timer? _timer;
  int _segundosRestantes = 0;

  Map<String, dynamic>? get _desafioActual =>
      (_desafios.isNotEmpty && _indiceActual < _desafios.length)
          ? _desafios[_indiceActual]
          : null;

  @override
  void initState() {
    super.initState();
    final int minutos = widget.experiencia['tiempo_limite_minutos'] ?? 5;
    _segundosRestantes = minutos * 60;

    // CORRECCIÓN USABILIDAD #3: Solo cargamos los desafíos; el reloj arranca cuando terminen de bajar
    _cargarDesafios();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _respuestaCtrl.dispose();
    super.dispose();
  }

  void _iniciarCronometro() {
    if (_timer != null && _timer!.isActive) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_segundosRestantes > 0) {
        setState(() {
          _segundosRestantes--;
        });

        // CORRECCIÓN ACCESIBILIDAD #4: Alerta explícita y vibración cuando queda exactamente 1 minuto
        if (_segundosRestantes == 60 && !_alertaUnMinutoMostrada && mounted) {
          _alertaUnMinutoMostrada = true;
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '¡ATENCIÓN! Queda 1 minuto de tiempo restante.',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.amberAccent,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        timer.cancel();
        _redirigirTiempoAgotado();
      }
    });
  }

  void _redirigirTiempoAgotado() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaTiempoAgotado(experiencia: widget.experiencia),
      ),
    );
  }

  String get _tiempoFormateado {
    int minutos = _segundosRestantes ~/ 60;
    int segundos = _segundosRestantes % 60;
    return '${minutos.toString().padLeft(2, '0')}:${segundos.toString().padLeft(2, '0')}';
  }

  // Etiqueta hablada para lectores de pantalla (TalkBack / VoiceOver)
  String get _tiempoSemantica {
    int minutos = _segundosRestantes ~/ 60;
    int segundos = _segundosRestantes % 60;
    return 'Tiempo restante: $minutos minutos y $segundos segundos';
  }

  Future<void> _cargarDesafios() async {
    try {
      // Traemos también elemento_fisico(*) para poder validar su codigo_corto si el usuario no puede escanear el QR
      final data = await supabase
          .from('desafio')
          .select('*, pista(*), elemento_fisico(*)')
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('orden_resolucion', ascending: true);

      if (!mounted) return;
      setState(() {
        _desafios = data;
        _indiceActual = 0;
        _isLoading = false;
      });

      // Iniciamos el cronómetro recién cuando ya hay desafíos listos en pantalla
      if (_desafios.isNotEmpty) {
        _iniciarCronometro();
      }
    } catch (e) {
      // CORRECCIÓN USABILIDAD #6: No exponer $e crudo al jugador
      debugPrint('Error interno al cargar desafíos: $e');
      if (!mounted) return;
      setState(() {
        _mensajeError = 'No se pudo establecer conexión con el servidor de la misión. Verifica tu internet e intenta nuevamente.';
        _isLoading = false;
      });
    }
  }

  // CORRECCIÓN USABILIDAD #2: Confirmación antes de abortar la partida
  Future<void> _confirmarAbortar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.redAccent, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Abandonar misión?',
                style: TextStyle(color: Colors.redAccent, fontSize: 18),
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Seguro que quieres abandonar la misión? Perderás el progreso actual.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Continuar jugando', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sí, abortar'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      _timer?.cancel();
      Navigator.pop(context);
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


    final String limpioSinGuiones = codigoCorrecto.replaceAll('-', '');
    final String prefijoCincoCaracteres = limpioSinGuiones.length >= 5
        ? limpioSinGuiones.substring(0, 5)
        : limpioSinGuiones;


    String? codigoCortoElemento;
    final elem = _desafioActual!['elemento_fisico'];
    if (elem is Map) {
      codigoCortoElemento = elem['codigo_corto']?.toString().trim().toUpperCase();
    }


    final bool coincideRespuesta = codigoLimpio == codigoCorrecto ||
        (codigoCortoElemento != null && codigoCortoElemento.isNotEmpty && codigoLimpio == codigoCortoElemento) ||
        (_desafioActual!['tipo'] == 'qr' && codigoLimpio.length == 5 && codigoLimpio == prefijoCincoCaracteres);

    if (codigoLimpio.isEmpty || !coincideRespuesta) {
      setState(() {
        _bloqueoActivo = true;
        _exitoActivo = false;
      });
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Código incorrecto. Revisa el elemento físico e intenta de nuevo.'),
              ),
            ],
          ),
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

      final int puntosGanados = int.tryParse(_desafioActual!['puntos_otorgados']?.toString() ?? '100') ?? 100;
      _puntajeAcumulado += puntosGanados;

      if (_indiceActual + 1 < _desafios.length) {
        _indiceActual++;
      } else {
        _timer?.cancel();

        final int minutosMaximos = widget.experiencia['tiempo_limite_minutos'] ?? 5;
        final int segundosGastados = (minutosMaximos * 60) - _segundosRestantes;

        final String alias = SesionLocal.aliasJugador ?? 'INVITADO';

        supabase.from('participacion').insert({
          'id_experiencia': widget.experiencia['id_experiencia'],
          'alias': alias,
          'puntaje_obtenido': _puntajeAcumulado,
          'tiempo_segundos': segundosGastados,
        }).then((_) {
          debugPrint('Métricas de $alias guardadas exitosamente.');
        }).catchError((error) {
          debugPrint('Aviso DAT01 - Error al guardar métricas: $error');
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PantallaMisionCompletada(
              experiencia: widget.experiencia,
              segundosGastados: segundosGastados,
              puntajeTotal: _puntajeAcumulado,
            ),
          ),
        );
      }
    });
  }

  Future<void> _abrirEscanerQR(BuildContext context) async {
    if (_desafioActual == null) return;

    FocusScope.of(context).unfocus();

    final String? codigoEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaEscanerQr()),
    );

    if (codigoEscaneado == null || codigoEscaneado.trim().isEmpty) return;

    _verificarCodigoElementoFisico(codigoEscaneado);
  }

  // Modal directo para tipear el código en desafíos QR sin necesidad de abrir la cámara
  void _abrirModalCodigoManualQR() {
    final TextEditingController manualQrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.cyanAccent, width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        title: const Text('Código Manual del Objeto', style: TextStyle(color: Colors.cyanAccent, fontSize: 18)),
        content: TextField(
          controller: manualQrCtrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Ingresa el código impreso bajo el QR',
            labelStyle: TextStyle(color: Colors.grey, letterSpacing: 0),
            hintText: 'Ej: A7X9K',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              final texto = manualQrCtrl.text.trim();
              Navigator.pop(dialogContext);
              if (texto.isNotEmpty) {
                _verificarCodigoElementoFisico(texto);
              }
            },
            child: const Text('Verificar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exp = widget.experiencia;
    final String? textoPista = _obtenerTextoPista();

    final int numeroDesafio = _indiceActual + 1;
    final int totalDesafios = _desafios.length;

    final bool pocoTiempo = _segundosRestantes <= 60;
    final Color colorTimer = pocoTiempo ? Colors.redAccent : Colors.cyanAccent;

    // Estado explícito en texto + ícono (Corrección Accesibilidad #3: No depender solo del color)
    String textoEstadoDesafio = 'ESTADO: EN CURSO';
    IconData iconoEstadoDesafio = Icons.terminal;
    Color colorEstadoDesafio = Colors.cyanAccent;

    if (_exitoActivo) {
      textoEstadoDesafio = 'ESTADO: ¡CÓDIGO VERIFICADO!';
      iconoEstadoDesafio = Icons.check_circle;
      colorEstadoDesafio = Colors.greenAccent;
    } else if (_bloqueoActivo) {
      textoEstadoDesafio = 'ESTADO: CÓDIGO INCORRECTO';
      iconoEstadoDesafio = Icons.error_outline;
      colorEstadoDesafio = Colors.redAccent;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmarAbortar();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: 'Abortar misión y volver al inicio',
                child: TextButton.icon(
                  onPressed: _confirmarAbortar,
                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                  label: const Text(
                    'ABORTAR',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      Semantics(
                        label: 'Puntaje acumulado: $_puntajeAcumulado puntos',
                        child: Row(
                          children: [
                            const ExcludeSemantics(
                              child: Icon(Icons.star, color: Colors.amberAccent, size: 14),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_puntajeAcumulado PTS',
                              style: const TextStyle(
                                color: Colors.amberAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Semantics(
                        liveRegion: pocoTiempo,
                        label: _tiempoSemantica,
                        child: Row(
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                pocoTiempo ? Icons.warning_amber_rounded : Icons.circle,
                                color: colorTimer,
                                size: pocoTiempo ? 16 : 10,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'TIEMPO: $_tiempoFormateado',
                              style: TextStyle(
                                color: colorTimer,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        body: _isLoading
            ?  Center(
                child: Semantics(
                  label: 'Cargando desafíos de la misión',
                  child: CircularProgressIndicator(color: Colors.cyan),
                ),
              )
            : _mensajeError != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off, color: Colors.redAccent, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _mensajeError!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 15),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isLoading = true;
                                _mensajeError = null;
                              });
                              _cargarDesafios();
                            },
                            icon: const Icon(Icons.refresh, color: Colors.cyanAccent),
                            label: const Text('Reintentar', style: TextStyle(color: Colors.cyanAccent)),
                          ),
                        ],
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
                                style: const TextStyle(color: Colors.grey, fontSize: 14, letterSpacing: 1.5),
                              ),
                              const SizedBox(height: 6),

                              Semantics(
                                label: 'Progreso de la misión: Desafío $numeroDesafio de $totalDesafios',
                                child: BarraProgresoEscape(
                                  desafioActual: numeroDesafio,
                                  totalDesafios: totalDesafios,
                                ),
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
                                    ExcludeSemantics(
                                      child: Icon(Icons.search, color: Colors.amberAccent, size: 20),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'BUSCA LA PISTA EN EL ELEMENTO FÍSICO DEL STAND',
                                        style: TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Semantics(
                                liveRegion: true,
                                label: '$textoEstadoDesafio. Acertijo actual: ${_desafioActual!['descripcion'] ?? ''}',
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    border: Border.all(
                                      color: _exitoActivo ? Colors.greenAccent : (_bloqueoActivo ? Colors.redAccent : Colors.cyan),
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_exitoActivo ? Colors.greenAccent : (_bloqueoActivo ? Colors.redAccent : Colors.cyan)).withAlpha(30),
                                        blurRadius: 15,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Indicador explícito con ícono + texto además del color (Accesibilidad #3)
                                      Row(
                                        children: [
                                          Icon(iconoEstadoDesafio, color: colorEstadoDesafio, size: 16),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              textoEstadoDesafio,
                                              style: TextStyle(
                                                color: colorEstadoDesafio,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(color: Colors.white24, height: 20),
                                      const Text(
                                        'DESCRIPCIÓN DEL ACERTIJO',
                                        style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        (_desafioActual!['descripcion'] != null && _desafioActual!['descripcion'].toString().trim().isNotEmpty)
                                            ? _desafioActual!['descripcion'].toString()
                                            : 'Inspecciona el elemento físico señalado en el stand.',
                                        style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              if (_desafioActual!['tipo'] == 'texto') ...[
                                TextField(
                                  controller: _respuestaCtrl,
                                  enabled: !_exitoActivo,
                                  textCapitalization: TextCapitalization.characters,
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                  decoration: InputDecoration(
                                    labelText: 'Ingresa la respuesta o código',
                                    labelStyle: const TextStyle(color: Colors.grey),
                                    errorText: _bloqueoActivo ? 'Secuencia incorrecta. Intenta de nuevo.' : null,
                                    filled: true,
                                    fillColor: const Color(0xFF1A1A1A),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(color: _bloqueoActivo ? Colors.redAccent : Colors.white24),
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
                                    onPressed: _exitoActivo ? null : () => _verificarCodigoElementoFisico(_respuestaCtrl.text),
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
                                          onPressed: _exitoActivo ? null : () => _abrirEscanerQR(context),
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
                                      const SizedBox(height: 12),
                                      // Alternativa visible sin necesidad de entrar a la cámara (GAM08 + Accesibilidad)
                                      TextButton.icon(
                                        onPressed: _exitoActivo ? null : _abrirModalCodigoManualQR,
                                        icon: const Icon(Icons.keyboard, color: Colors.cyanAccent, size: 18),
                                        label: const Text(
                                          'Ingresar código del objeto manualmente',
                                          style: TextStyle(color: Colors.cyanAccent),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              Center(
                                child: Semantics(
                                  button: true,
                                  label: _mostrarPista ? 'Pista ya revelada en pantalla' : 'Solicitar una pista de ayuda',
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
                              ),

                              if (_mostrarPista && textoPista != null) ...[
                                const SizedBox(height: 16),
                                Semantics(
                                  liveRegion: true,
                                  label: 'Pista de ayuda: $textoPista',
                                  child: TarjetaPistaAyuda(textoPista: textoPista),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }
}