import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'landing_screen.dart';
import 'pantalla_admin_desafios.dart';
import 'pantalla_elementos_fisicos.dart';
import 'pantalla_admin_hoja_armado.dart';

class PantallaAdmin extends StatefulWidget {
  const PantallaAdmin({super.key});

  @override
  State<PantallaAdmin> createState() => _PantallaAdminState();
}

class _PantallaAdminState extends State<PantallaAdmin> {
  final supabase = Supabase.instance.client;

  Map<String, dynamic>? _standActual;
  List<dynamic> _experiencias = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos() async {
    try {
      final usuarioActual = supabase.auth.currentUser;
      if (usuarioActual == null) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La sesión de administrador expiró. Inicia sesión nuevamente.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      final standData = await supabase
          .from('stand')
          .select()
          .eq('id_admin', usuarioActual.id)
          .maybeSingle();

      if (standData != null) {
        final expData = await supabase
            .from('experiencia')
            .select()
            .eq('id_stand', standData['id_stand'])
            .order('nombre');

        if (!mounted) return;
        setState(() {
          _standActual = standData;
          _experiencias = expData;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error interno al cargar panel admin: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudieron cargar los datos del stand. Verifica tu conexión.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleEstadoStand(bool nuevoEstado) async {
    if (_standActual == null) return;
    try {
      await supabase
          .from('stand')
          .update({'activo': nuevoEstado})
          .eq('id_stand', _standActual!['id_stand']);
      if (!mounted) return;
      setState(() => _standActual!['activo'] = nuevoEstado);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevoEstado
                ? 'STAND ABIERTO AL PÚBLICO'
                : 'STAND BLOQUEADO TEMPORALMENTE',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: nuevoEstado ? Colors.green : Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint('Error al cambiar estado del stand: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo actualizar el estado del stand.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _toggleActivacionExperiencia(
    String idExperiencia,
    bool nuevoEstado,
  ) async {
    try {
      await supabase
          .from('experiencia')
          .update({'activa': nuevoEstado})
          .eq('id_experiencia', idExperiencia);
      await _cargarDatosCompletos();
    } catch (e) {
      debugPrint('Error al cambiar estado de experiencia: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo cambiar el estado de la experiencia.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _generarYDescargarPDFStand(
    String nombreStand,
    String idStand,
    String codigoCorto,
  ) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  nombreStand.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 40,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'PUNTO DE ENLACE DE OPERARIOS',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 40),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: idStand,
                  width: 300,
                  height: 300,
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  '¿TU CÁMARA NO FUNCIONA?',
                  style: const pw.TextStyle(
                    fontSize: 20,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'INGRESA EL CÓDIGO: $codigoCorto',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Cartel_Stand_$codigoCorto',
    );
  }

  void _mostrarDialogoQRStand() {
    if (_standActual == null) return;

    final String idStand = _standActual!['id_stand'].toString();
    final String codigoCorto = _standActual!['codigo_corto'].toString();
    final String nombre = _standActual!['nombre_marca'].toString();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            side: const BorderSide(color: Colors.cyanAccent, width: 1),
            borderRadius: BorderRadius.circular(12),
          ),
          content: SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'QR MAESTRO',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre.toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: idStand,
                      version: QrVersions.auto,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CÓDIGO MANUAL: $codigoCorto',
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _generarYDescargarPDFStand(
                          nombre,
                          idStand,
                          codigoCorto,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text(
                        'DESCARGAR CARTEL',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _mostrarModalFormulario({Map<String, dynamic>? experienciaAEditar}) {
    if (_standActual == null) return;

    final formKey = GlobalKey<FormState>();
    final bool esEdicion = experienciaAEditar != null;

    final nombreCtrl = TextEditingController(
      text: esEdicion ? experienciaAEditar['nombre'] : '',
    );
    final descCtrl = TextEditingController(
      text: esEdicion ? experienciaAEditar['descripcion'] : '',
    );
    final tiempoCtrl = TextEditingController(
      text: esEdicion
          ? experienciaAEditar['tiempo_limite_minutos'].toString()
          : '',
    );
    final recompensaCtrl = TextEditingController(
      text: esEdicion
          ? (experienciaAEditar['mensaje_recompensa_final'] ?? '')
          : '',
    );
    bool experienciaActiva = esEdicion ? experienciaAEditar['activa'] : true;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setStateModal) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: Text(
                esEdicion ? 'Editar Experiencia' : 'Nueva Experiencia',
                style: const TextStyle(color: Colors.cyan),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                      TextFormField(
                        controller: tiempoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Minutos (3 a 7)',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Requerido';
                          }
                          final num = int.tryParse(value);
                          if (num == null || num < 1) {
                            return 'Ingresa un número mayor a 0';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: recompensaCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Código o Mensaje de Recompensa',
                          labelStyle: TextStyle(color: Colors.grey),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Requerido'
                            : null,
                      ),
                      const SizedBox(height: 15),
                      SwitchListTile(
                        title: const Text(
                          'Activa',
                          style: TextStyle(color: Colors.white),
                        ),
                        activeThumbColor: Colors.cyan,
                        value: experienciaActiva,
                        onChanged: (val) =>
                            setStateModal(() => experienciaActiva = val),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogContext);
                    setState(() => _isLoading = true);

                    try {
                      final datos = {
                        'id_stand': _standActual!['id_stand'],
                        'nombre': nombreCtrl.text.trim(),
                        'descripcion': descCtrl.text.trim(),
                        'tiempo_limite_minutos': int.parse(
                          tiempoCtrl.text.trim(),
                        ),
                        'mensaje_recompensa_final': recompensaCtrl.text.trim(),
                        'activa': experienciaActiva,
                      };

                      if (esEdicion) {
                        await supabase
                            .from('experiencia')
                            .update(datos)
                            .eq(
                              'id_experiencia',
                              experienciaAEditar['id_experiencia'],
                            );
                      } else {
                        await supabase.from('experiencia').insert(datos);
                      }
                      await _cargarDatosCompletos();
                    } catch (e) {
                      debugPrint('Error al guardar experiencia: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se pudo guardar la experiencia. Intenta nuevamente.',
                          ),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                      setState(() => _isLoading = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
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

  Future<void> _eliminarExperiencia(
    String idExperiencia,
    String nombreExp,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '¿Eliminar Experiencia?',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          'Se eliminará "$nombreExp" de forma permanente junto con sus desafíos.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    setState(() => _isLoading = true);
    try {
      await supabase
          .from('experiencia')
          .delete()
          .eq('id_experiencia', idExperiencia);
      await _cargarDatosCompletos();
    } catch (e) {
      debugPrint('Error al eliminar experiencia: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar la experiencia.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _cerrarSesion() async {
    await supabase.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LandingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SISTEMA CENTRAL',
          style: TextStyle(
            color: Colors.cyanAccent,
            fontSize: 16,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      floatingActionButton: _standActual == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _mostrarModalFormulario(),
              backgroundColor: Colors.cyan,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.add),
              label: const Text(
                'NUEVA EXPERIENCIA',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _standActual == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amberAccent,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'NO TIENES UN STAND ASIGNADO',
                    style: TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _cerrarSesion,
                    child: const Text('Volver'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: _standActual!['activo']
                          ? Colors.greenAccent
                          : Colors.redAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_standActual!['activo']
                                    ? Colors.greenAccent
                                    : Colors.redAccent)
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _standActual!['nombre_marca']
                                      .toString()
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _standActual!['activo']
                                      ? 'ESTADO: ABIERTO'
                                      : 'ESTADO: BLOQUEADO',
                                  style: TextStyle(
                                    color: _standActual!['activo']
                                        ? Colors.greenAccent
                                        : Colors.redAccent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Semantics(
                            label: 'Interruptor para abrir o bloquear el stand al público',
                            child: Switch(
                              activeThumbColor: Colors.greenAccent,
                              inactiveThumbColor: Colors.redAccent,
                              inactiveTrackColor: Colors.redAccent.withAlpha(
                                50,
                              ),
                              value: _standActual!['activo'],
                              onChanged: _toggleEstadoStand,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.vpn_key,
                                color: Colors.amberAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CÓDIGO: ${_standActual!['codigo_corto']}',
                                style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: _mostrarDialogoQRStand,
                            icon: const Icon(Icons.qr_code_2, size: 18),
                            label: const Text(
                              'VER QR',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.cyanAccent,
                              side: const BorderSide(color: Colors.cyanAccent),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'EXPERIENCIAS DEL STAND',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: _experiencias.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay experiencias configuradas.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 8,
                            bottom: 88,
                          ),
                          itemCount: _experiencias.length,
                          itemBuilder: (context, index) {
                            final exp = _experiencias[index];
                            final String nombreExp =
                                exp['nombre']?.toString() ?? 'Experiencia';

                            return Card(
                              color: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Colors.cyan,
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                nombreExp.toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Tiempo: ${exp['tiempo_limite_minutos']} min | Estado: ${exp['activa'] ? 'Activa' : 'Pausada'}',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Semantics(
                                          label:
                                              'Activar o pausar experiencia $nombreExp',
                                          child: Switch(
                                            activeThumbColor: Colors.cyan,
                                            value: exp['activa'],
                                            onChanged: (bool val) =>
                                                _toggleActivacionExperiencia(
                                                  exp['id_experiencia'],
                                                  val,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Colors.white24,
                                      height: 20,
                                    ),

                                    // CORRECCIÓN USABILIDAD #8: Acción destructiva separada a la izquierda y tooltips en íconos
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          tooltip:
                                              'Eliminar experiencia $nombreExp',
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            color: Colors.redAccent,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => _eliminarExperiencia(
                                            exp['id_experiencia'],
                                            nombreExp,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              _mostrarModalFormulario(
                                                experienciaAEditar: exp,
                                              ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.cyan,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'EDITAR',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PantallaAdminDesafios(
                                                    experiencia: exp,
                                                  ),
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.amberAccent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'DESAFÍOS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PantallaElementosFisicos(
                                                    experiencia: exp,
                                                  ),
                                            ),
                                          ),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.greenAccent,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'OBJETOS',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          tooltip:
                                              'Ver hoja de armado del stand',
                                          icon: const Icon(
                                            Icons.list_alt,
                                            color: Colors.purpleAccent,
                                          ),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  PantallaAdminHojaArmado(
                                                    experiencia: exp,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
