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
      // Hacemos el select a la tabla correcta
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

void _mostrarModalCreacion() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final tiempoCtrl = TextEditingController();
    final recompensaCtrl = TextEditingController();
    bool experienciaActiva = true;

    showDialog(
      context: context, // Este es el context principal de la pantalla
      builder: (dialogContext) { // RENOMBRADO para no pisar el original
        return StatefulBuilder(
          builder: (builderContext, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Nueva Experiencia', style: TextStyle(color: Colors.cyan)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre (Ej: Operación Núcleo)', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Descripción / Instrucciones', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: tiempoCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tiempo límite (Minutos)', labelStyle: TextStyle(color: Colors.grey))),
                    TextField(controller: recompensaCtrl, decoration: const InputDecoration(labelText: 'Mensaje recompensa final', labelStyle: TextStyle(color: Colors.grey))),
                    const SizedBox(height: 15),
                    SwitchListTile(
                      title: const Text('Experiencia Activa', style: TextStyle(color: Colors.white)),
                      activeThumbColor: Colors.cyan, // AVISO 1 SOLUCIONADO
                      value: experienciaActiva,
                      onChanged: (val) => setStateModal(() => experienciaActiva = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext), // Usamos el context del modal
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext); // Cerramos el modal primero
                    setState(() => _isLoading = true);
                    
                    try {
                      final stand = await supabase.from('stand').select('id_stand').limit(1).single();

                      await supabase.from('experiencia').insert({
                        'id_stand': stand['id_stand'],
                        'nombre': nombreCtrl.text,
                        'descripcion': descCtrl.text,
                        'tiempo_limite_minutos': int.tryParse(tiempoCtrl.text) ?? 15,
                        'mensaje_recompensa_final': recompensaCtrl.text,
                        'activa': experienciaActiva,
                      });
                      
                      await _cargarExperiencias(); 
                    } catch (e) {
                      if (!mounted) return; // AVISO 2 SOLUCIONADO: Ahora evalúa correctamente el State principal
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear: $e', style: const TextStyle(color: Colors.white)), backgroundColor: Colors.red)
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black),
                  child: const Text('Guardar'),
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
        onPressed: _mostrarModalCreacion,
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
                    title: Text(exp['nombre'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), // Ajustado al campo 'nombre'
                    subtitle: Text('Tiempo: ${exp['tiempo_limite_minutos']} min | Activa: ${exp['activa'] ? "Sí" : "No"}', style: const TextStyle(color: Colors.grey)), // Ajustado a 'tiempo_limite_minutos'
                    trailing: const Icon(Icons.settings, color: Colors.cyan),
                  ),
                );
              },
            ),
    );
  }
}