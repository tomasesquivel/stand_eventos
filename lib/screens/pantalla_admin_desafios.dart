import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaAdminDesafios extends StatefulWidget {
  final Map<String, dynamic> experiencia;

  const PantallaAdminDesafios({super.key, required this.experiencia});

  @override
  State<PantallaAdminDesafios> createState() => _PantallaAdminDesafiosState();
}

class _PantallaAdminDesafiosState extends State<PantallaAdminDesafios> {
  final supabase = Supabase.instance.client;
  List<dynamic> _desafios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDesafios();
  }

  Future<void> _cargarDesafios() async {
    try {
      final data = await supabase
          .from('desafio')
          .select()
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('orden_resolucion', ascending: true);
          
      setState(() {
        _desafios = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  // Criterio 1: Modal con formulario para cargar el acertijo
  void _mostrarModalDesafio() {
    final formKey = GlobalKey<FormState>();
    final ordenCtrl = TextEditingController(text: (_desafios.length + 1).toString());
    final respuestaCtrl = TextEditingController();
    final puntosCtrl = TextEditingController(text: '100');
    String tipoSeleccionado = 'texto'; // Por defecto, según modelo BD

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Nuevo Desafío', style: TextStyle(color: Colors.amberAccent)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Criterio 2: Validaciones de campos obligatorios
                      TextFormField(
                        controller: ordenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Orden de resolución (Ej: 1)', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: tipoSeleccionado,
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Tipo de desafío', labelStyle: TextStyle(color: Colors.grey)),
                        items: const [
                          DropdownMenuItem(value: 'texto', child: Text('Ingreso de Palabra Clave')),
                          DropdownMenuItem(value: 'qr', child: Text('Escanear QR')),
                        ],
                        onChanged: (val) => setStateModal(() => tipoSeleccionado = val!),
                      ),
                      TextFormField(
                        controller: respuestaCtrl,
                        decoration: const InputDecoration(labelText: 'Respuesta correcta / ID del QR', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? 'La respuesta es obligatoria' : null,
                      ),
                      TextFormField(
                        controller: puntosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Puntos otorgados', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Criterio 2: Impide guardar si falta información
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);
                    
                    try {
                      await supabase.from('desafio').insert({
                        'id_experiencia': widget.experiencia['id_experiencia'],
                        'orden_resolucion': int.parse(ordenCtrl.text),
                        'tipo': tipoSeleccionado,
                        'respuesta_correcta': respuestaCtrl.text.trim(),
                        'puntos_otorgados': int.parse(puntosCtrl.text),
                      });
                      
                      await _cargarDesafios(); 
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black),
                  child: const Text('Guardar Desafío'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('DESAFÍOS: ${widget.experiencia['nombre'].toString().toUpperCase()}', style: const TextStyle(color: Colors.amberAccent, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amberAccent),
      ),
      // Criterio 1: Botón visible para cargar el desafío
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarModalDesafio,
        backgroundColor: Colors.amberAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NUEVO DESAFÍO', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.amberAccent))
        : _desafios.isEmpty
          ? const Center(child: Text('No hay desafíos configurados aún.', style: TextStyle(color: Colors.grey)))
          // Criterio 3: Listado dentro de la configuración
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _desafios.length,
              itemBuilder: (context, index) {
                final des = _desafios[index];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.amberAccent, width: 0.5), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.amberAccent, foregroundColor: Colors.black, child: Text(des['orden_resolucion'].toString())),
                    title: Text('Respuesta: ${des['respuesta_correcta']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tipo: ${des['tipo'].toString().toUpperCase()} | Puntos: ${des['puntos_otorgados']}', style: const TextStyle(color: Colors.grey)),
                  ),
                );
              },
            ),
    );
  }
}