import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PantallaEscanerQr extends StatefulWidget {
  const PantallaEscanerQr({super.key});

  @override
  State<PantallaEscanerQr> createState() => _PantallaEscanerQrState();
}

class _PantallaEscanerQrState extends State<PantallaEscanerQr> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _codigoDetectado = false;
  bool _linternaActiva = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  // Fallback GAM08 + Accesibilidad: Permite tipear el código si la cámara falla o no tiene permisos
  void _abrirIngresoManualAlternativo() {
    final TextEditingController manualCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyanAccent, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Ingresar Código Manual',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Si la cámara no enfoca o no tienes permisos, escribe el código alfanumérico impreso junto al QR:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: manualCtrl,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2),
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Código del objeto o stand',
                  labelStyle: TextStyle(color: Colors.grey, letterSpacing: 0),
                  hintText: 'Ej: EXPO24',
                  hintStyle: TextStyle(color: Colors.white38),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyan),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent, width: 2),
                  ),
                ),
              ),
            ],
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
                final texto = manualCtrl.text.trim();
                if (texto.isNotEmpty) {
                  Navigator.pop(dialogContext); // Cierra el diálogo
                  Navigator.pop(context, texto); // Devuelve el código a la pantalla anterior
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: const Text(
          'ESCANEAR CÓDIGO QR',
          style: TextStyle(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 1.5),
        ),
        actions: [
          IconButton(
            tooltip: _linternaActiva ? 'Apagar linterna' : 'Encender linterna',
            icon: Icon(
              _linternaActiva ? Icons.flash_on : Icons.flash_off,
              color: _linternaActiva ? Colors.amberAccent : Colors.cyanAccent,
            ),
            onPressed: () async {
              await _scannerController.toggleTorch();
              if (!mounted) return;
              setState(() => _linternaActiva = !_linternaActiva);
            },
          ),
          IconButton(
            tooltip: 'Cambiar de cámara',
            icon: const Icon(Icons.cameraswitch, color: Colors.cyanAccent),
            onPressed: () => _scannerController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Semantics(
            label: 'Visor de cámara para escanear código QR',
            child: MobileScanner(
              controller: _scannerController,
              onDetect: (capture) {
                if (_codigoDetectado) return;

                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  final String codigoEscaneado = barcodes.first.rawValue!.trim();
                  if (codigoEscaneado.isEmpty) return;

                  _codigoDetectado = true;
                  Navigator.pop(context, codigoEscaneado);
                }
              },

              errorBuilder: (context, error) {
                String mensajePermiso = 'No se pudo iniciar la cámara del dispositivo.';
                if (error.errorCode == MobileScannerErrorCode.permissionDenied) {
                  mensajePermiso = 'Permiso de cámara denegado.\nHabilítalo en los ajustes o ingresa el código manualmente.';
                } else if (error.errorCode == MobileScannerErrorCode.unsupported) {
                  mensajePermiso = 'Este dispositivo no soporta el escaneo por cámara.';
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        border: Border.all(color: Colors.redAccent, width: 1.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.no_photography_outlined, color: Colors.redAccent, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'CÁMARA NO DISPONIBLE',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mensajePermiso,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _abrirIngresoManualAlternativo,
                            icon: const Icon(Icons.keyboard),
                            label: const Text(
                              'INGRESAR CÓDIGO MANUAL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Marco visual guía (Ignorado por lectores de pantalla por ser decorativo)
          IgnorePointer(
            child: ExcludeSemantics(
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.6), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),

          // Panel inferior con instrucciones y botón de ingreso manual siempre accesible
          Positioned(
            bottom: 32,
            left: 24,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Apunta al código QR del objeto físico',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Semantics(
                    button: true,
                    label: 'Escribir código manualmente si no puedes escanear el QR',
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.amberAccent,
                        side: const BorderSide(color: Colors.amberAccent),
                      ),
                      onPressed: _abrirIngresoManualAlternativo,
                      icon: const Icon(Icons.keyboard, size: 18),
                      label: const Text('¿No enfoca? Escribir código manual'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}