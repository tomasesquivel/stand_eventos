import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PantallaEscanerQr extends StatefulWidget {
  const PantallaEscanerQr({super.key});

  @override
  State<PantallaEscanerQr> createState() => _PantallaEscanerQrState();
}

class _PantallaEscanerQrState extends State<PantallaEscanerQr> {
  bool _codigoDetectado = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
        title: const Text(
          'ESCANEAR OBJETO FÍSICO',
          style: TextStyle(color: Colors.cyanAccent, fontSize: 16, letterSpacing: 1.5),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            // Solo procesa el código una vez para evitar múltiples lecturas por segundo
            onDetect: (capture) {
              if (_codigoDetectado) return;
              
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                _codigoDetectado = true;
                final String codigoEscaneado = barcodes.first.rawValue!;
                
                // Cierra la cámara y le devuelve el código a la pantalla de juego
                Navigator.pop(context, codigoEscaneado);
              }
            },
          ),
          // Un marco visual simple para que el jugador apunte ahí
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'Apunta al código QR del objeto',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          )
        ],
      ),
    );
  }
}