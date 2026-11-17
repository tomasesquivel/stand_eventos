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
    FocusScope.of(context).unfocus();

    if (_emailCtrl.text.trim().isEmpty || _passCtrl.text.trim().isEmpty) {
      _mostrarError('Por favor, ingresa tu correo y contraseña.');
      return;
    }

    setState(() => _procesando = true);

    try {
      await supabase.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PantallaAdmin()),
      );
    } on AuthException catch (error) {
      debugPrint('Error de autenticación Supabase: ${error.message}');
      if (!mounted) return;
      _mostrarError('Acceso denegado: Correo o contraseña incorrectos.');
    } catch (e) {
      debugPrint('Error técnico en login: $e');
      if (!mounted) return;
      _mostrarError('No se pudo conectar con el servidor. Verifica tu conexión.');
    } finally {
      if (mounted) setState(() => _procesando = false);
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
              child: Text(
                mensaje,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
              const ExcludeSemantics(
                child: Icon(Icons.admin_panel_settings, size: 80, color: Colors.cyanAccent),
              ),
              const SizedBox(height: 30),
              const Text(
                'ACCESO ORGANIZADOR',
                textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5),
              ),
              const SizedBox(height: 40),

              // CAMPO EMAIL
              TextField(
                controller: _emailCtrl,
                style: const TextStyle(color: Colors.cyanAccent),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: InputDecoration(
                  labelText: 'CORREO ELECTRÓNICO',
                  labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 1.2),
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
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _procesando ? null : _iniciarSesion(),
                decoration: InputDecoration(
                  labelText: 'CÓDIGO DE SEGURIDAD',
                  labelStyle: const TextStyle(color: Colors.grey, letterSpacing: 1.2),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.cyan),
                  suffixIcon: IconButton(
                    // CORRECCIÓN ACCESIBILIDAD #2: Tooltip descriptivo para lectores de pantalla
                    tooltip: _ocultarPassword ? 'Mostrar contraseña' : 'Ocultar contraseña',
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
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                        )
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