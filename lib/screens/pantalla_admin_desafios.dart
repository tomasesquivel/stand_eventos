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
          .select('*, pista(*)')
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

  void _mostrarModalDesafio({Map<String, dynamic>? desafioAEditar}) {
    final formKey = GlobalKey<FormState>();
    final bool esEdicion = desafioAEditar != null;

    final ordenCtrl = TextEditingController(
      text: esEdicion ? desafioAEditar['orden_resolucion'].toString() : (_desafios.length + 1).toString(),
    );
    final descripcionCtrl = TextEditingController(
      text: esEdicion ? (desafioAEditar['descripcion'] ?? '') : '',
    );
    final respuestaCtrl = TextEditingController(
      text: esEdicion ? desafioAEditar['respuesta_correcta'] : '',
    );
    final puntosCtrl = TextEditingController(
      text: esEdicion ? desafioAEditar['puntos_otorgados'].toString() : '100',
    );

    String pistaExistenteText = '';
    String? idPistaExistente;
    if (esEdicion && desafioAEditar['pista'] != null && (desafioAEditar['pista'] as List).isNotEmpty) {
      pistaExistenteText = (desafioAEditar['pista'] as List)[0]['texto_ayuda'];
      idPistaExistente = (desafioAEditar['pista'] as List)[0]['id_pista'];
    }
    final pistaCtrl = TextEditingController(text: pistaExistenteText);
    String tipoSeleccionado = esEdicion ? desafioAEditar['tipo'] : 'texto';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                esEdicion ? 'Editar Desafío' : 'Nuevo Desafío',
                style: const TextStyle(color: Colors.amberAccent),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: ordenCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Orden de resolución (Ej: 1)',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Requerido';
                          if (int.tryParse(value.trim()) == null) return 'Ingrese un número válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: descripcionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción / Consigna del acertijo',
                          labelStyle: TextStyle(color: Colors.grey),
                          hintText: 'Ej: Encuentra la cifra oculta en el reloj...',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'La descripción es obligatoria' : null,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: tipoSeleccionado,
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Tipo de desafío',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'texto', child: Text('Ingreso de Palabra Clave')),
                          DropdownMenuItem(value: 'qr', child: Text('Escaneo QR')),
                        ],
                        onChanged: (val) => setStateModal(() => tipoSeleccionado = val!),
                      ),
                      TextFormField(
                        controller: respuestaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Respuesta correcta / ID QR',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'La respuesta es obligatoria' : null,
                      ),
                      TextFormField(
                        controller: puntosCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puntos otorgados',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Requerido';
                          if (int.tryParse(value.trim()) == null) return 'Ingrese un número válido';
                          return null;
                        },
                      ),
                      const Divider(color: Colors.white24, height: 30),
                      TextFormField(
                        controller: pistaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Pista / Ayuda (Opcional)',
                          labelStyle: TextStyle(color: Colors.cyan),
                          hintText: 'Ej: Busca debajo de la mesa',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
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
                    if (!formKey.currentState!.validate()) return;

                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);

                    try {
                      final datosDesafio = {
                        'orden_resolucion': int.parse(ordenCtrl.text.trim()),
                        'descripcion': descripcionCtrl.text.trim(),
                        'tipo': tipoSeleccionado,
                        'respuesta_correcta': respuestaCtrl.text.trim(),
                        'puntos_otorgados': int.parse(puntosCtrl.text.trim()),
                      };

                      if (esEdicion) {
                        await supabase
                            .from('desafio')
                            .update(datosDesafio)
                            .eq('id_desafio', desafioAEditar['id_desafio']);

                        final textoPista = pistaCtrl.text.trim();
                        if (textoPista.isNotEmpty) {
                          if (idPistaExistente != null) {
                            await supabase
                                .from('pista')
                                .update({'texto_ayuda': textoPista})
                                .eq('id_pista', idPistaExistente);
                          } else {
                            await supabase.from('pista').insert({
                              'id_desafio': desafioAEditar['id_desafio'],
                              'texto_ayuda': textoPista,
                            });
                          }
                        } else if (idPistaExistente != null) {
                          await supabase.from('pista').delete().eq('id_pista', idPistaExistente);
                        }
                      } else {
                        datosDesafio['id_experiencia'] = widget.experiencia['id_experiencia'];
                        final nuevo = await supabase.from('desafio').insert(datosDesafio).select().single();

                        if (pistaCtrl.text.trim().isNotEmpty) {
                          await supabase.from('pista').insert({
                            'id_desafio': nuevo['id_desafio'],
                            'texto_ayuda': pistaCtrl.text.trim(),
                          });
                        }
                      }

                      await _cargarDesafios();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DESAFÍOS: ${widget.experiencia['nombre'].toString().toUpperCase()}',
          style: const TextStyle(color: Colors.amberAccent, fontSize: 16),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.amberAccent),
      ),
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
              ? const Center(
                  child: Text('No hay desafíos configurados aún.', style: TextStyle(color: Colors.grey)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _desafios.length,
                  itemBuilder: (context, index) {
                    final des = _desafios[index];
                    return Card(
                      color: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Colors.amberAccent, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.amberAccent,
                          foregroundColor: Colors.black,
                          child: Text(des['orden_resolucion'].toString()),
                        ),
                        title: Text(
                          des['descripcion'] ?? 'Sin descripción',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              'Respuesta: ${des['respuesta_correcta']} | Tipo: ${des['tipo'].toString().toUpperCase()} | Pts: ${des['puntos_otorgados']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (des['pista'] != null && (des['pista'] as List).isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Pista: ${(des['pista'] as List)[0]['texto_ayuda']}',
                                  style: const TextStyle(color: Colors.cyan, fontStyle: FontStyle.italic),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.cyan),
                              onPressed: () => _mostrarModalDesafio(desafioAEditar: des),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _eliminarDesafio(des['id_desafio']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Future<void> _eliminarDesafio(String idDesafio) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿Eliminar desafío?', style: TextStyle(color: Colors.redAccent)),
        content: const Text(
          'Se eliminará este acertijo y su pista asociada de forma permanente.',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() => _isLoading = true);

    try {
      await supabase.from('desafio').delete().eq('id_desafio', idDesafio);

      final restantes = await supabase
          .from('desafio')
          .select('id_desafio')
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('orden_resolucion');

      for (int i = 0; i < restantes.length; i++) {
        await supabase
            .from('desafio')
            .update({'orden_resolucion': i + 1})
            .eq('id_desafio', restantes[i]['id_desafio']);
      }

      await _cargarDesafios();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }
}