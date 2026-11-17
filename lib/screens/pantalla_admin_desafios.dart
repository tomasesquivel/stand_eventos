import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_generative_ai/google_generative_ai.dart';


class PantallaAdminDesafios extends StatefulWidget {
  final Map<String, dynamic> experiencia;

  const PantallaAdminDesafios({super.key, required this.experiencia});

  @override
  State<PantallaAdminDesafios> createState() => _PantallaAdminDesafiosState();
}

class _PantallaAdminDesafiosState extends State<PantallaAdminDesafios> {
  final supabase = Supabase.instance.client;
  List<dynamic> _desafios = [];
  List<dynamic> _elementosDisponibles = []; // Lista para almacenar los objetos físicos
  bool _isLoading = true;

// Clave de API de Gemini (Google Generative AI)
  static const String _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');


  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // Carga combinada de desafíos y elementos físicos
  Future<void> _cargarDatos() async {
    try {
      final dataDesafios = await supabase
          .from('desafio')
          .select('*, pista(*), elemento_fisico(nombre, codigo_qr)')
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('orden_resolucion', ascending: true);

      final dataElementos = await supabase
          .from('elemento_fisico')
          .select()
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('nombre', ascending: true);

      if (!mounted) return;
      setState(() {
        _desafios = dataDesafios;
        _elementosDisponibles = dataElementos;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los desafíos y elementos físicos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ADM25: Modal del Asistente Creativo con IA (Gemini)
  Future<void> _abrirModalGeneradorIA({
    required TextEditingController controladorDescripcion,
    required TextEditingController controladorRespuesta,
    required String tipoDesafio,
    int? idElementoSeleccionado,
  }) async {
    // Pre-cargamos el nombre de la misión como sugerencia de temática
    final TextEditingController tematicaCtrl = TextEditingController(
      text: widget.experiencia['nombre']?.toString() ?? '',
    );

    // Si es desafío QR y hay un objeto elegido, sugerimos el nombre del objeto (ej: "Caja Fuerte").
    // Si es de texto, pre-cargamos la respuesta escrita hasta el momento.
    String sugerenciaObjetivo = '';
    if (tipoDesafio == 'qr' && idElementoSeleccionado != null) {
      final el = _elementosDisponibles.firstWhere(
        (e) => e['id_elemento'] == idElementoSeleccionado,
        orElse: () => null,
      );
      if (el != null) sugerenciaObjetivo = el['nombre'].toString();
    } else if (tipoDesafio == 'texto') {
      sugerenciaObjetivo = controladorRespuesta.text;
    }

    final TextEditingController respuestaIaCtrl = TextEditingController(
      text: sugerenciaObjetivo,
    );
    bool cargandoIA = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogIaContext) {
        return StatefulBuilder(
          builder: (ctx, setModalIaState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: Colors.amberAccent, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              title: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.amberAccent),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Generador de Acertijos IA',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Indicá la temática y la respuesta (o el objeto a buscar). Gemini redactará el acertijo sin mencionar la palabra clave.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tematicaCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Temática (Ej: Piratas, Cyberpunk)',
                        labelStyle: TextStyle(color: Colors.grey),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amberAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: respuestaIaCtrl,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: tipoDesafio == 'qr'
                            ? 'Objeto a encontrar (Ej: RELOJ)'
                            : 'Respuesta esperada (Ej: FUEGO)',
                        labelStyle: const TextStyle(color: Colors.grey),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amberAccent),
                        ),
                      ),
                    ),
                    if (cargandoIA) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(color: Colors.amberAccent),
                      const SizedBox(height: 8),
                      const Text(
                        'Redactando acertijo con Gemini...',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: cargandoIA ? null : () => Navigator.pop(dialogIaContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: cargandoIA
                      ? null
                      : () async {
                          final tematica = tematicaCtrl.text.trim();
                          final respuesta = respuestaIaCtrl.text.trim();

                          if (tematica.isEmpty || respuesta.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Completá tanto la temática como la respuesta.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                            return;
                          }

                          setModalIaState(() => cargandoIA = true);

                          try {
                            final prompt = '''
                            Actúa como un diseñador experto de juegos de Escape Room.
                            Redacta un acertijo breve, inmersivo y enigmático (máximo 3 oraciones) ambientado en la temática: "$tematica".
                            La respuesta exacta o el objeto que el jugador debe deducir es: "$respuesta".

                            REGLAS ESTRICTAS:
                            1. PROHIBIDO incluir la palabra "$respuesta" (ni variaciones directas de la misma) dentro del texto del acertijo.
                            2. Devuelve ÚNICAMENTE el texto del acertijo listo para mostrar al jugador, sin saludos, sin introducciones, sin comillas y sin explicaciones adicionales.
                            ''';

                            final model = GenerativeModel(
                              model: 'gemini-3-flash-preview',
                              apiKey: _geminiApiKey,
                            );

                            final response = await model
                                .generateContent([Content.text(prompt)])
                                .timeout(const Duration(seconds: 10));

                            final textoGenerado = response.text?.trim();

                            if (!mounted || !dialogIaContext.mounted) return;

                            if (textoGenerado != null && textoGenerado.isNotEmpty) {
                              controladorDescripcion.text = textoGenerado;
                              if (tipoDesafio == 'texto') {
                                controladorRespuesta.text = respuesta.toUpperCase();
                              }

                              Navigator.pop(dialogIaContext);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('¡Acertijo generado! Podés revisarlo y editarlo antes de guardar.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted || !dialogIaContext.mounted) return;
                            setModalIaState(() => cargandoIA = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('No se pudo generar el acertijo. Intenta nuevamente.'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.bolt, size: 18),
                  label: const Text('Generar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
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

    int? idElementoSeleccionado = esEdicion ? desafioAEditar['id_elemento'] : null;

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
                          final n = int.tryParse(value.trim());
                          if (n == null || n <= 0) return 'Ingrese un número positivo válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // ADM25 - Criterio 1: Botón visible de "Generar con IA" en el formulario
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amberAccent,
                            side: const BorderSide(color: Colors.amberAccent),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          onPressed: () async {
                            await _abrirModalGeneradorIA(
                              controladorDescripcion: descripcionCtrl,
                              controladorRespuesta: respuestaCtrl,
                              tipoDesafio: tipoSeleccionado,
                              idElementoSeleccionado: idElementoSeleccionado,
                            );
                            // Refrescamos el modal del desafío por si cambió algún estado visual
                            setStateModal(() {});
                          },
                          icon: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text(
                            'Generar con IA',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),

                      TextFormField(
                        controller: descripcionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción / Consigna del desafío',
                          labelStyle: TextStyle(color: Colors.grey),
                          hintText: 'Ej: Busca en el reloj...',
                          hintStyle: TextStyle(color: Colors.white38),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Indica el acertijo de la misión'
                                : null,
                      ),
                      const SizedBox(height: 10),

                      // Selector de Elementos Físicos
                      DropdownButtonFormField<int?>(
                        initialValue: idElementoSeleccionado,
                        dropdownColor: const Color(0xFF1A1A1A),
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Objeto Físico Vinculado (Opcional/QR)',
                          labelStyle: TextStyle(color: Colors.greenAccent),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Ninguno (Solo pantalla)'),
                          ),
                          ..._elementosDisponibles.map((el) {
                            return DropdownMenuItem<int?>(
                              value: el['id_elemento'],
                              child: Text(el['nombre']),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setStateModal(() {
                            idElementoSeleccionado = val;
                            // Si ya estaba en modo QR y cambia de objeto, actualizamos el código automáticamente
                            if (tipoSeleccionado == 'qr' && val != null) {
                              final el = _elementosDisponibles.firstWhere((e) => e['id_elemento'] == val);
                              respuestaCtrl.text = el['codigo_qr'] ?? '';
                            }
                          });
                        },
                        validator: (value) {
                          if (tipoSeleccionado == 'qr' && value == null) {
                            return 'Un desafío QR requiere un objeto físico obligatorio.';
                          }
                          return null;
                        },
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
                          DropdownMenuItem(value: 'qr', child: Text('Escaneo QR físico')),
                        ],
                        onChanged: (val) {
                          setStateModal(() {
                            tipoSeleccionado = val!;
                            if (tipoSeleccionado == 'qr' && idElementoSeleccionado != null) {
                              final el = _elementosDisponibles.firstWhere((e) => e['id_elemento'] == idElementoSeleccionado);
                              respuestaCtrl.text = el['codigo_qr'] ?? '';
                            }
                          });
                        },
                      ),
                      TextFormField(
                        controller: respuestaCtrl,
                        decoration: InputDecoration(
                          labelText: tipoSeleccionado == 'qr' ? 'Código UUID del QR (Automático)' : 'Respuesta correcta',
                          labelStyle: const TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        readOnly: tipoSeleccionado == 'qr',
                        validator: (value) =>
                            value == null || value.trim().isEmpty ? 'La respuesta/código es obligatoria' : null,
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
                          final pts = int.tryParse(value.trim());
                          if (pts == null || pts <= 0) return 'Ingrese un puntaje mayor a 0';
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

                    if (tipoSeleccionado == 'qr' && idElementoSeleccionado == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debe seleccionar un objeto físico para desafíos QR'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);

                    try {
                      final datosDesafio = {
                        'orden_resolucion': int.parse(ordenCtrl.text.trim()),
                        'descripcion': descripcionCtrl.text.trim(),
                        'tipo': tipoSeleccionado,
                        'respuesta_correcta': respuestaCtrl.text.trim(),
                        'puntos_otorgados': int.parse(puntosCtrl.text.trim()),
                        'id_elemento': idElementoSeleccionado,
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

                      await _cargarDatos();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo guardar el desafío. Intenta nuevamente.'),
                          backgroundColor: Colors.redAccent,
                        ),
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
                              'Tipo: ${des['tipo'].toString().toUpperCase()} | Pts: ${des['puntos_otorgados']}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (des['elemento_fisico'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '📌 Objeto: ${des['elemento_fisico']['nombre']}',
                                  style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
                                ),
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

      await _cargarDatos();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el desafío. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isLoading = false);
    }
  }
}