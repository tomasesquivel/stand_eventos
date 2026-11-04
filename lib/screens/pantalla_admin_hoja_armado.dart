import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaAdminHojaArmado extends StatefulWidget {
  final Map<String, dynamic> experiencia;

  const PantallaAdminHojaArmado({super.key, required this.experiencia});

  @override
  State<PantallaAdminHojaArmado> createState() => _PantallaAdminHojaArmadoState();
}

class _PantallaAdminHojaArmadoState extends State<PantallaAdminHojaArmado> {
  final supabase = Supabase.instance.client;
  List<dynamic> _elementos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarHojaArmado();
  }

  // Criterio 1 y 2: Cruzamos los Elementos Físicos con sus Desafíos dependientes
  Future<void> _cargarHojaArmado() async {
    try {
      // Supabase hace un JOIN automático gracias a la Foreign Key que creamos
      final data = await supabase
          .from('elemento_fisico')
          .select('*, desafio(*)') // Trae el objeto y un array con todos los desafíos que lo usan
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('nombre', ascending: true);

      setState(() {
        _elementos = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String nombreExp = widget.experiencia['nombre'].toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('HOJA DE ARMADO - $nombreExp', style: const TextStyle(fontSize: 16, color: Colors.greenAccent)),
        iconTheme: const IconThemeData(color: Colors.greenAccent),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.greenAccent))
          : _elementos.isEmpty
              ? const Center(child: Text('No hay elementos físicos registrados.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _elementos.length,
                  itemBuilder: (context, index) {
                    final elemento = _elementos[index];
                    // Recuperamos el array de desafíos anidados
                    final desafiosVinculados = (elemento['desafio'] as List<dynamic>?) ?? [];

                    return Card(
                      color: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.greenAccent, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined, color: Colors.greenAccent),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    elemento['nombre'].toString().toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                            if (elemento['descripcion'] != null && elemento['descripcion'].toString().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('Ubicación: ${elemento['descripcion']}', style: const TextStyle(color: Colors.white70)),
                            ],
                            const Divider(color: Colors.white24, height: 24),
                            const Text('DESAFÍOS DEPENDIENTES:', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            
                            // Si el array está vacío, avisamos. Si tiene contenido, listamos cada desafío.
                            if (desafiosVinculados.isEmpty)
                              const Text('⚠️ Ningún desafío utiliza este objeto actualmente.', style: TextStyle(color: Colors.orangeAccent, fontStyle: FontStyle.italic))
                            else
                              ...desafiosVinculados.map((des) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('• ', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                                      Expanded(
                                        child: Text(
                                          'Desafío #${des['orden_resolucion']}: ${des['descripcion']}\n(Tipo: ${des['tipo'].toString().toUpperCase()})',
                                          style: const TextStyle(color: Colors.white, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}