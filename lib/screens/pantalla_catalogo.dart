import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/app_route_observer.dart';
import '../utils/sesion_local.dart';
import 'landing_screen.dart';
import 'pantalla_mision.dart';

class PantallaCatalogo extends StatefulWidget {
  const PantallaCatalogo({super.key});

  @override
  State<PantallaCatalogo> createState() => _PantallaCatalogoState();
}

class _PantallaCatalogoState extends State<PantallaCatalogo> with RouteAware {
  final supabase = Supabase.instance.client;
  List<dynamic> _experiencias = [];
  bool _isLoading = true;
  String? _mensajeError;
  ModalRoute<dynamic>? _route;

  @override
  void initState() {
    super.initState();
    _cargarExperienciasActivas();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route != _route) {
      if (_route != null) {
        appRouteObserver.unsubscribe(this);
      }
      _route = route;
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // TICKET ADM22: Carga solo las experiencias vinculadas al stand escaneado
  Future<void> _cargarExperienciasActivas() async {
    final String? idStand = SesionLocal.idStandActual;

    if (idStand == null) {
      if (!mounted) return;
      setState(() {
        _mensajeError =
            'ERROR DE ENLACE: No se detectó un stand activo en la memoria.';
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await supabase
          .from('experiencia')
          .select()
          .eq('activa', true)
          .eq('id_stand', idStand) // <-- EL FILTRO MULTI-TENANT CLAVE
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

  void _desconectarSistema() {
    SesionLocal.desconectarStand();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String alias = SesionLocal.aliasJugador ?? 'INVITADO';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading:
            false, // Quitamos la flecha de volver por seguridad
        title: const Text(
          'CATÁLOGO DE MISIONES',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new, color: Colors.redAccent),
            onPressed: _desconectarSistema,
            tooltip: 'Desconectar',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'OPERARIO: $alias',
              style: const TextStyle(
                color: Colors.cyanAccent,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _mensajeError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _desconectarSistema,
                      child: const Text('REINICIAR CONEXIÓN'),
                    ),
                  ],
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
                final String idExp = exp['id_experiencia'].toString();
                final bool yaCompletada = SesionLocal.misionesCompletadas
                    .contains(idExp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: yaCompletada ? Colors.greenAccent : Colors.cyan,
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: (yaCompletada ? Colors.greenAccent : Colors.cyan)
                            .withAlpha(20),
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
                            const Icon(
                              Icons.check_circle,
                              color: Colors.greenAccent,
                            ),
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
                          const Icon(
                            Icons.timer_outlined,
                            color: Colors.cyanAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${exp['tiempo_limite_minutos']} MINUTOS',
                            style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: yaCompletada
                              ? () {
                                  final mensaje =
                                      exp['mensaje_recompensa_final']
                                          ?.toString()
                                          .trim();
                                  showDialog(
                                    context: context,
                                    builder: (dialogContext) => AlertDialog(
                                      backgroundColor: const Color(0xFF1A1A1A),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: const BorderSide(
                                          color: Colors.cyanAccent,
                                        ),
                                      ),
                                      title: const Text(
                                        'Código de recompensa',
                                        style: TextStyle(
                                          color: Colors.cyanAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SelectableText(
                                        mensaje?.isNotEmpty == true ? mensaje! : 'Sin código de recompensa disponible',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(dialogContext),
                                          child: const Text(
                                            'Cerrar',
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () async {
                                            await Clipboard.setData(
                                              ClipboardData(
                                                text:
                                                    mensaje?.isNotEmpty == true
                                                    ? mensaje!
                                                    : '',
                                              ),
                                            );
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Código copiado al portapapeles',
                                                    ),
                                                    backgroundColor: Color(
                                                      0xFF1A1A1A,
                                                    ),
                                                  ),
                                                );
                                          },
                                          icon: const Icon(Icons.copy),
                                          label: const Text('Copiar'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.cyanAccent,
                                            foregroundColor: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PantallaMision(experiencia: exp),
                                    ),
                                  ).then((_) {
                                    setState(() {});
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: yaCompletada
                                ? Colors.green.withAlpha(50)
                                : Colors.cyan,
                            disabledBackgroundColor: const Color(0xFF2A2A2A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide(
                                color: yaCompletada
                                    ? Colors.greenAccent
                                    : Colors.transparent,
                              ),
                            ),
                          ),
                          child: Text(
                            yaCompletada
                                ? 'VER CÓDIGO DE RECOMPENSA'
                                : 'INICIAR MISIÓN',
                            style: TextStyle(
                              color: yaCompletada
                                  ? Colors.greenAccent
                                  : Colors.black,
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
