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

  // --- MOTOR DE VALIDACIÓN CON BASE DE DATOS ---
  Future<void> _validarAcceso(String codigo) async {
    // 1. Mostramos un círculo de carga mientras consultamos a Supabase
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
    );

    try {
      final codigoLimpio = codigo.trim();
      
      // Verificamos si escaneó un QR (UUID) o si tipeó a mano (Código corto)
      final esUuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false).hasMatch(codigoLimpio);

      // Consulta a la tabla stand
      final query = supabase.from('stand').select('id_stand, activo');
      final respuesta = await (esUuid 
          ? query.eq('id_stand', codigoLimpio).maybeSingle()
          : query.eq('codigo_corto', codigoLimpio.toUpperCase()).maybeSingle());

      if (!mounted) return;
      Navigator.pop(context); // Ocultamos el círculo de carga

      if (respuesta == null) {
        _mostrarError('Error: Código de stand incorrecto o no existe.');
      } else if (respuesta['activo'] == false) {
        _mostrarError('Error: El stand se encuentra inactivo en este momento.');
      } else {
        // Guardamos el ID del stand en RAM y avanzamos
        SesionLocal.idStandActual = respuesta['id_stand'].toString();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PantallaIngresoAlias()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Ocultamos el círculo de carga
      _mostrarError('Error de conexión con el servidor.');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- REEMPLAZO DEL SIMULADOR QR ---
  Future<void> _abrirEscanerQR() async {
    // Abre la cámara real reutilizando tu pantalla existente
    final String? codigoEscaneado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PantallaEscanerQr()),
    );

    // Si detectó un código (y no volvieron para atrás), lo validamos
    if (codigoEscaneado != null && codigoEscaneado.trim().isNotEmpty) {
      await _validarAcceso(codigoEscaneado);
    }
  }

  // --- REEMPLAZO DEL SIMULADOR MANUAL ---
  void _abrirIngresoManual() {
    final TextEditingController codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Ingreso Manual', style: TextStyle(color: Colors.cyan)),
          content: TextField(
            controller: codigoController,
            style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
            textCapitalization: TextCapitalization.characters,
            maxLength: 6, // Limitamos a 6 caracteres
            decoration: const InputDecoration(
              hintText: 'Ej: EXPO24',
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 1),
              counterText: '',
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Cerramos el popup de texto
                if (codigoController.text.trim().isNotEmpty) {
                  _validarAcceso(codigoController.text.trim()); // Validamos con DB
                }
              },
              child: const Text('Validar', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
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
                    Icon(Icons.circle, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 8),
                    Text(
                      'NEO_ESCAPE',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              
              // BOTÓN GIGANTE CONECTADO AL ESCÁNER REAL
              GestureDetector(
                onTap: _abrirEscanerQR,
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
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 60, color: Colors.cyan),
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
              const SizedBox(height: 50),
              const Text('SITUATE ANTE EL DISPOSITIVO DEL ESCAPE', style: TextStyle(color: Colors.cyan, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text('Escanea el código QR maestro del stand para iniciar el enlace', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              const SizedBox(height: 40),
              
              // BOTÓN CONECTADO AL INGRESO MANUAL REAL
              OutlinedButton.icon(
                onPressed: _abrirIngresoManual,
                icon: const Icon(Icons.keyboard, color: Colors.grey),
                label: const Text('Ingresar Código Manual', style: TextStyle(color: Colors.grey)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}