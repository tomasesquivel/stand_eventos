import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaElementosFisicos extends StatefulWidget {
  final Map<String, dynamic> experiencia;

  const PantallaElementosFisicos({super.key, required this.experiencia});

  @override
  State<PantallaElementosFisicos> createState() => _PantallaElementosFisicosState();
}

class _PantallaElementosFisicosState extends State<PantallaElementosFisicos> {
  final _supabase = Supabase.instance.client;
  final TextEditingController _nombreCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  
  List<dynamic> _elementos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarElementos();
  }

  // Criterio 3: Muestra en formato de lista los elementos de ESTA experiencia
  Future<void> _cargarElementos() async {
    try {
      final data = await _supabase
          .from('elemento_fisico')
          .select()
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('id_elemento', ascending: true);

      setState(() {
        _elementos = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar elementos: $e');
      setState(() => _isLoading = false);
    }
  }

  // Criterio 1 y 2: Da de alta un objeto real y lo guarda en la DB
  Future<void> _agregarElemento() async {
    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await _supabase.from('elemento_fisico').insert({
        'id_experiencia': widget.experiencia['id_experiencia'],
        'nombre': nombre,
        'descripcion': _descCtrl.text.trim(),
      });

      _nombreCtrl.clear();
      _descCtrl.clear();
      await _cargarElementos();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Elemento registrado con éxito'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

 @override
  Widget build(BuildContext context) {
    final String nombreExp = widget.experiencia['nombre'].toString().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('ELEMENTOS FÍSICOS - $nombreExp', style: const TextStyle(fontSize: 16)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'REGISTRAR NUEVO OBJETO',
              style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const SizedBox(height: 16),
            
            // Campo para el Nombre
            TextField(
              controller: _nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Nombre del objeto',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'Ej: Candado rojo, Caja fuerte...',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),

            // Campo para la Descripción
            TextField(
              controller: _descCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Descripción / Ubicación',
                labelStyle: const TextStyle(color: Colors.grey),
                hintText: 'Ej: Ubicado debajo de la mesa principal',
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // Botón de Agregar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _agregarElemento,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text('AGREGAR ELEMENTO', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'OBJETOS VINCULADOS',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
            const Divider(color: Colors.white24),
            
            // EL EXPANDED CRÍTICO QUE EVITA EL CRASHEO
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                  : _elementos.isEmpty
                      ? const Center(
                          child: Text('No hay elementos físicos registrados.', style: TextStyle(color: Colors.grey)))
                      : ListView.builder(
                          itemCount: _elementos.length,
                          itemBuilder: (context, index) {
                            final item = _elementos[index];
                            return Card(
                              color: const Color(0xFF1A1A1A),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent),
                                title: Text(item['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                  item['descripcion']?.toString().isNotEmpty == true 
                                      ? item['descripcion'] 
                                      : 'Sin descripción adicional', 
                                  style: const TextStyle(color: Colors.white54)
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    await _supabase.from('elemento_fisico').delete().eq('id_elemento', item['id_elemento']);
                                    _cargarElementos();
                                  },
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
  
}