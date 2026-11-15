import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_admin.dart';

class PantallaLoginAdmin extends StatefulWidget {
  const PantallaLoginAdmin({super.key});

  @override
  State<PantallaLoginAdmin> createState() => _PantallaLoginAdminState();
}

class _PantallaLoginAdminState extends State<PantallaLoginAdmin> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final supabase = Supabase.instance.client;
  
  bool _procesando = false;
  bool _ocultarPassword = true;

  Future<void> _iniciarSesion() async {
    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _mostrarError('FALTAN CREDENCIALES');
      return;
    }

    setState(() => _procesando = true);

    try {
      // Intento de conexión con Supabase Auth
      await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;
      
      // Si el login es exitoso, viaja al Panel de Administración
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaAdmin()),
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _mostrarError('ACCESO DENEGADO: ${error.message}');
    } catch (e) {
      if (!mounted) return;
      _mostrarError('ERROR DEL SISTEMA: $e');
    } finally {
      if (mounted) setState(() => _procesando = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyanAccent),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 80, color: Colors.cyanAccent),
              const SizedBox(height: 30),
              const Text(
                'ACCESO ORGANIZADOR',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'INGRESA TUS CREDENCIALES DE SISTEMA',
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),

              // CAMPO EMAIL
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.cyanAccent),
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'CORREO ELECTRÓNICO',
                  labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 1.5),
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.cyan),
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

              // CAMPO CONTRASEÑA
              TextField(
                controller: _passCtrl,
                style: const TextStyle(color: Colors.cyanAccent),
                obscureText: _ocultarPassword,
                decoration: InputDecoration(
                  labelText: 'CÓDIGO DE SEGURIDAD',
                  labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 1.5),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyan),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _ocultarPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _ocultarPassword = !_ocultarPassword;
                      });
                    },
                  ),
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
              const SizedBox(height: 40),

              // BOTÓN INGRESO
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _procesando ? null : _iniciarSesion,
                  icon: _procesando 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: Text(
                    _procesando ? 'VERIFICANDO...' : 'AUTENTICAR',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.cyan.withAlpha(50),
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