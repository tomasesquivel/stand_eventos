import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final supabase = Supabase.instance.client;
  
  List<dynamic> _experiencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarExperiencias();
  }

  Future<void> _cargarExperiencias() async {
    try {
      final data = await supabase.from('experiencia').select().order('nombre');
      setState(() {
        _experiencias = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar: $e')));
    }
  }

  Future<void> _toggleActivacion(String idExperiencia, bool nuevoEstado) async {
    try {
      // Actualizamos solo el campo 'activa' en la base de datos
      await supabase
          .from('experiencia')
          .update({'activa': nuevoEstado})
          .eq('id_experiencia', idExperiencia);
          
      // Refrescamos la lista para reflejar el cambio en la interfaz
      await _cargarExperiencias();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar estado: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red)
      );
    }
  }

  // MODIFICACIÓN: Ahora recibe parámetros opcionales para saber si es edición
  void _mostrarModalFormulario({Map<String, dynamic>? experienciaAEditar}) {
    final formKey = GlobalKey<FormState>();
    final bool esEdicion = experienciaAEditar != null;

    // Autocompletamos si estamos editando
    final nombreCtrl = TextEditingController(text: esEdicion ? experienciaAEditar['nombre'] : '');
    final descCtrl = TextEditingController(text: esEdicion ? experienciaAEditar['descripcion'] : '');
    final tiempoCtrl = TextEditingController(text: esEdicion ? experienciaAEditar['tiempo_limite_minutos'].toString() : '');
    final recompensaCtrl = TextEditingController(text: esEdicion ? (experienciaAEditar['mensaje_recompensa_final'] ?? '') : '');
    bool experienciaActiva = esEdicion ? experienciaAEditar['activa'] : true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              // Cambia el título dinámicamente
              title: Text(esEdicion ? 'Editar Experiencia' : 'Nueva Experiencia', style: const TextStyle(color: Colors.cyan)),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(labelText: 'Nombre (Ej: Operación Núcleo)', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? 'El nombre es obligatorio' : null,
                      ),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(labelText: 'Descripción / Instrucciones', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) => value == null || value.trim().isEmpty ? 'La descripción es obligatoria' : null,
                      ),
                      TextFormField(
                        controller: tiempoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Tiempo límite (Minutos)', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'El tiempo es obligatorio';
                          if (int.tryParse(value) == null) return 'Debe ingresar un número válido';
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: recompensaCtrl,
                        decoration: const InputDecoration(labelText: 'Mensaje recompensa final', labelStyle: TextStyle(color: Colors.grey)),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text('Experiencia Activa', style: TextStyle(color: Colors.white)),
                        activeThumbColor: Colors.cyan,
                        value: experienciaActiva,
                        onChanged: (val) => setStateModal(() => experienciaActiva = val),
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
                      // Preparamos el objeto con los datos validados
                      final datos = {
                        'nombre': nombreCtrl.text.trim(),
                        'descripcion': descCtrl.text.trim(),
                        'tiempo_limite_minutos': int.parse(tiempoCtrl.text.trim()),
                        'mensaje_recompensa_final': recompensaCtrl.text.trim(),
                        'activa': experienciaActiva,
                      };

                      if (esEdicion) {
                        // Flujo UPDATE
                        await supabase
                            .from('experiencia')
                            .update(datos)
                            .eq('id_experiencia', experienciaAEditar['id_experiencia']);
                      } else {
                        // Flujo INSERT
                        final stand = await supabase.from('stand').select('id_stand').limit(1).single();
                        datos['id_stand'] = stand['id_stand']; // Agregamos la FK
                        await supabase.from('experiencia').insert(datos);
                      }
                      
                      await _cargarExperiencias(); 
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al guardar: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red)
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black),
                  child: Text(esEdicion ? 'Actualizar' : 'Guardar'),
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
        title: const Text('PANEL ADM - EXPERIENCIAS', style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarModalFormulario(), // Sin parámetros = Crear
        backgroundColor: Colors.cyan,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('NUEVA EXPERIENCIA', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : _experiencias.isEmpty
          ? const Center(child: Text('No hay experiencias configuradas.', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _experiencias.length,
              itemBuilder: (context, index) {
                final exp = _experiencias[index];
                return Card(
                  color: const Color(0xFF1A1A1A),
                  shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(8)),
                  child: ListTile(
                    title: Text(exp['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Tiempo: ${exp['tiempo_limite_minutos']} min | Activa: ${exp['activa'] ? "Sí" : "No"}', style: const TextStyle(color: Colors.grey)),
                    // MODIFICACIÓN: El ícono ahora es un botón que abre el modal pasando los datos
                   // ADM03: Control rápido junto a cada experiencia listada
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          activeThumbColor: Colors.cyan,
                          value: exp['activa'],
                          onChanged: (bool newValue) => _toggleActivacion(exp['id_experiencia'], newValue),
                        ),
                        const SizedBox(width: 8), // Separador visual
                        TextButton(
                          onPressed: () => _mostrarModalFormulario(experienciaAEditar: exp),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.cyan,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('EDITAR', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}