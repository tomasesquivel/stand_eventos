import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'pantalla_mision.dart';

class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({super.key});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final supabase = Supabase.instance.client;
  List<dynamic> _experiencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      // Trae TODAS las experiencias activas
      final data = await supabase.from('experiencia').select().eq('activa', true);
      setState(() {
        _experiencias = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECCIONAR MISIÓN', style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.cyan),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _experiencias.isEmpty
              ? const Center(child: Text('No hay misiones disponibles en este stand.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _experiencias.length,
                  itemBuilder: (context, index) {
                    final exp = _experiencias[index];
                    return GestureDetector(
                      onTap: () {
                        // Navega a la misión y le pasa los datos específicos de la opción elegida
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PantallaMision(experiencia: exp)),
                        );
                      },
                      child: Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Colors.cyan, width: 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(exp['nombre'].toString().toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('Tiempo límite: ${exp['tiempo_limite_minutos']} min', style: const TextStyle(color: Colors.grey)),
                              const SizedBox(height: 12),
                              const Align(
                                alignment: Alignment.centerRight,
                                child: Text('INICIAR >', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}