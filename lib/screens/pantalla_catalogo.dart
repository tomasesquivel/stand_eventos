import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/sesion_local.dart';
import 'pantalla_juego.dart';

class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({super.key});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> {
  final supabase = Supabase.instance.client;
  List<dynamic> _experiencias = [];
  bool _isLoading = true;
  String? _mensajeError;

  @override
  void initState() {
    super.initState();
    _cargarExperienciasActivas();
  }

  // Carga solo las experiencias que el admin marcó como activas
  Future<void> _cargarExperienciasActivas() async {
    try {
      final data = await supabase
          .from('experiencia')
          .select()
          .eq('activa', true)
          .order('id_experiencia', ascending: true);

      if (!mounted) return;
      setState(() {
        _experiencias = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mensajeError = 'Error al conectar con el servidor: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Leemos el alias de la memoria RAM (o ponemos 'INVITADO' por si entraron directo)
    final String alias = SesionLocal.aliasJugador ?? 'INVITADO';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'CATÁLOGO DE MISIONES',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'OPERARIO: $alias',
              style: const TextStyle(color: Colors.cyanAccent, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _mensajeError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      _mensajeError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                )
              : _experiencias.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay misiones activas en este stand.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(24.0),
                      itemCount: _experiencias.length,
                      itemBuilder: (context, index) {
                        final exp = _experiencias[index];
                        
                        // GAM02: Verificamos en la RAM si el ID de esta misión ya se ganó
                        final String idExp = exp['id_experiencia'].toString();
                        final bool yaCompletada = SesionLocal.misionesCompletadas.contains(idExp);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 24.0),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            border: Border.all(
                              // Si ya la ganó, el borde se pone verde; si no, queda cyan
                              color: yaCompletada ? Colors.greenAccent : Colors.cyan,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (yaCompletada ? Colors.greenAccent : Colors.cyan).withAlpha(20),
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      exp['nombre'].toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  if (yaCompletada)
                                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                exp['descripcion']?.toString() ?? 'Sin descripción',
                                style: const TextStyle(color: Colors.grey, height: 1.5),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: Colors.cyanAccent, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${exp['tiempo_limite_minutos']} MINUTOS',
                                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  // GAM02 (Criterio 3): Si ya está completada, el botón se bloquea (onPressed en null)
                                  onPressed: yaCompletada
                                      ? null
                                      : () {
                                          // Navega al motor del juego pasándole los datos de la experiencia
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => PantallaJuego(experiencia: exp),
                                            ),
                                          ).then((_) {
                                            // Cuando vuelve del juego (gane o pierda), recarga la pantalla 
                                            // para actualizar el estado del botón a verde si corresponde.
                                            setState(() {});
                                          });
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: yaCompletada ? Colors.green.withAlpha(50) : Colors.cyan,
                                    disabledBackgroundColor: const Color(0xFF2A2A2A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: yaCompletada ? Colors.greenAccent : Colors.transparent,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    yaCompletada ? 'RECOMPENSA RECLAMADA' : 'INICIAR MISIÓN',
                                    style: TextStyle(
                                      color: yaCompletada ? Colors.greenAccent : Colors.black,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}