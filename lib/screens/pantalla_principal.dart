import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_ingreso_alias.dart';
import 'pantalla_escaner_qr.dart';
import '../utils/sesion_local.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final supabase = Supabase.instance.client;

  Future<void> _validarAcceso(String codigo) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Semantics(
          label: 'Validando código de stand',
          child: const CircularProgressIndicator(color: Colors.cyanAccent),
        ),
      ),
    );

    try {
      final codigoLimpio = codigo.trim();

      final esUuid = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      ).hasMatch(codigoLimpio);

      final query = supabase.from('stand').select('id_stand, activo');
      final respuesta = await (esUuid
          ? query.eq('id_stand', codigoLimpio).maybeSingle()
          : query.eq('codigo_corto', codigoLimpio.toUpperCase()).maybeSingle());

      if (!mounted) return;
      Navigator.pop(context);

      if (respuesta == null) {
        _mostrarError('Código de stand incorrecto o no existe.');
      } else if (respuesta['activo'] == false) {
        _mostrarError('El stand se encuentra inactivo en este momento.');
      } else {
        SesionLocal.idStandActual = respuesta['id_stand'].toString();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PantallaIngresoAlias()),
        );
      }
    } catch (e) {
      debugPrint('Error técnico al validar acceso al stand: $e');
      if (!mounted) return;
      Navigator.pop(context);
      _mostrarError('No se pudo conectar con el servidor. Verifica tu internet.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _abrirEscanerQR() async {
    final String? codigoEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaEscanerQr()),
    );

    if (codigoEscaneado != null && codigoEscaneado.trim().isNotEmpty) {
      await _validarAcceso(codigoEscaneado);
    }
  }

  void _abrirIngresoManual() {
    final TextEditingController codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyan, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Ingreso Manual', style: TextStyle(color: Colors.cyanAccent)),
          content: TextField(
            controller: codigoController,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código del Stand',
              labelStyle: TextStyle(color: Colors.grey, letterSpacing: 0),
              hintText: 'Ej: EXPO24',
              hintStyle: TextStyle(color: Colors.white38, letterSpacing: 1),
              counterText: '',
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                final texto = codigoController.text.trim();
                Navigator.pop(dialogContext);
                if (texto.isNotEmpty) {
                  _validarAcceso(texto);
                }
              },
              child: const Text('Validar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.cyan, width: 2),
                    bottom: BorderSide(color: Colors.cyan, width: 2),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'NEO_ESCAPE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // CORRECCIÓN ACCESIBILIDAD Y USABILIDAD: Botón Material accesible con Semantics y ripple circular
              Semantics(
                button: true,
                label: 'Escanear código QR del stand para jugar',
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: Colors.cyan, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.cyan.withAlpha(128), blurRadius: 30, spreadRadius: 5),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: Colors.cyanAccent.withAlpha(60),
                      onTap: _abrirEscanerQR,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ExcludeSemantics(
                            child: Icon(Icons.qr_code_scanner, size: 60, color: Colors.cyan),
                          ),
                          SizedBox(height: 15),
                          Text(
                            'Escanear QR para\nJugar',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SITÚATE ANTE EL DISPOSITIVO DEL ESCAPE',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Escanea el código QR maestro del stand para iniciar el enlace',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),

              Semantics(
                button: true,
                label: 'Ingresar código de stand manualmente con el teclado',
                child: OutlinedButton.icon(
                  onPressed: _abrirIngresoManual,
                  icon: const Icon(Icons.keyboard, color: Colors.cyanAccent),
                  label: const Text(
                    'Ingresar Código Manual',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.cyan),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}