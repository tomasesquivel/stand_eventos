import 'package:flutter/material.dart';
import '../utils/sesion_local.dart';
import 'pantalla_catalogo.dart'; 

class PantallaIngresoAlias extends StatefulWidget {
  const PantallaIngresoAlias({super.key});

  @override
  State<PantallaIngresoAlias> createState() => _PantallaIngresoAliasState();
}

class _PantallaIngresoAliasState extends State<PantallaIngresoAlias> {
  final TextEditingController _aliasCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _ingresarAlSistema() {
    if (_formKey.currentState!.validate()) {

      SesionLocal.aliasJugador = _aliasCtrl.text.trim().toUpperCase();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaCatalogo()), 
      );
    }
  }

  @override
  void dispose() {
    _aliasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Ícono de identidad / hacker
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withAlpha(20),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.fingerprint, size: 80, color: Colors.cyanAccent),
                ),
                const SizedBox(height: 40),

                const Text(
                  'IDENTIFICACIÓN DE OPERARIO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ingresa tu Alias para registrar tu progreso y reclamar recompensas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 40),

                TextFormField(
                  controller: _aliasCtrl,
                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, letterSpacing: 2),
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'EJ: NEO, TRINITY, MATRIX',
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 16, letterSpacing: 1),
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
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El Alias es obligatorio.';
                    }
                    if (value.trim().length < 3) {
                      return 'Debe tener al menos 3 caracteres.';
                    }
                    if (value.trim().length > 12) {
                      return 'Máximo 12 caracteres.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _ingresarAlSistema,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CONECTAR AL SISTEMA',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
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