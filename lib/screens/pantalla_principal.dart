import 'package:flutter/material.dart';
import 'pantalla_mision.dart';
import 'pantalla_admin.dart';


class PantallaPrincipal extends StatelessWidget {
  const PantallaPrincipal({super.key});

  // Simula la lectura de la cámara (Botón gigante)
  void _simularEscaneoQR(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Simulador de Cámara', style: TextStyle(color: Colors.cyan)),
          content: const Text('¿Qué código detectó la cámara?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Código QR inválido o stand inactivo.'),
                    backgroundColor: Colors.redAccent,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Simular QR Inválido', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!context.mounted) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PantallaMision()),
                );
              },
              child: const Text('Simular QR Válido', style: TextStyle(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  // Simula el ingreso manual por teclado
  void _simularIngresoManual(BuildContext context) {
    final TextEditingController codigoController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Ingreso Manual', style: TextStyle(color: Colors.cyan)),
          content: TextField(
            controller: codigoController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Código del stand (Ej: ALPHA-01)',
              hintStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyan)),
              focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.cyanAccent)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (!context.mounted) return;
                // Validamos un código de prueba (ALPHA-01)
                if (codigoController.text.trim().toUpperCase() == 'ALPHA-01') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PantallaMision()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: Código de stand incorrecto o inactivo.'),
                      backgroundColor: Colors.redAccent,
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: const Text('Validar', style: TextStyle(color: Colors.cyanAccent)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white24),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PantallaAdmin())),
          )
        ],
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
              
              // BOTÓN GIGANTE DEL ESCÁNER
              GestureDetector(
                onTap: () => _simularEscaneoQR(context),
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
                child: Text('Escanea el código QR de inicio de sala para iniciar el descifrado', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 14)),
              ),
              const SizedBox(height: 40),
              
              // BOTÓN INGRESO MANUAL
              OutlinedButton.icon(
                onPressed: () => _simularIngresoManual(context), // <-- Conectado al nuevo simulador
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