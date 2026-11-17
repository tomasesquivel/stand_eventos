import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  Future<void> _cargarElementos() async {
    try {
      final data = await _supabase
          .from('elemento_fisico')
          .select()
          .eq('id_experiencia', widget.experiencia['id_experiencia'])
          .order('id_elemento', ascending: true);

      if (!mounted) return;
      setState(() {
        _elementos = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar elementos: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudieron cargar los objetos físicos.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _agregarElemento() async {
    if (_isLoading) return;

    final nombre = _nombreCtrl.text.trim();
    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, ingresa el nombre del objeto físico.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
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
          const SnackBar(
            content: Text('Elemento registrado con éxito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al guardar elemento: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo registrar el objeto. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // CORRECCIÓN USABILIDAD Y ACCESIBILIDAD: Confirmación antes de eliminar un objeto físico
  Future<void> _confirmarEliminarElemento(Map<String, dynamic> item) async {
    final String nombre = item['nombre']?.toString() ?? 'este objeto';

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('¿Eliminar objeto físico?', style: TextStyle(color: Colors.redAccent)),
        content: Text(
          '¿Estás seguro de que quieres eliminar "$nombre"? Si ya imprimiste su código QR, dejará de funcionar.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('elemento_fisico').delete().eq('id_elemento', item['id_elemento']);
      await _cargarElementos();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Objeto eliminado correctamente.')),
        );
      }
    } catch (e) {
      debugPrint('Error al eliminar objeto: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo eliminar el objeto. Intenta nuevamente.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _generarYDescargarPDF(String nombreElemento, String codigoQr, String? codigoCorto) async {
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
                  nombreElemento.toUpperCase(),
                  style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 30),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: codigoQr,
                  width: 300,
                  height: 300,
                ),
                pw.SizedBox(height: 30),
                pw.Text(
                  'ESCANEA ESTE CÓDIGO CON LA APP',
                  style: const pw.TextStyle(fontSize: 20, color: PdfColors.grey700),
                ),
                if (codigoCorto != null && codigoCorto.isNotEmpty) ...[
                  pw.SizedBox(height: 15),
                  pw.Text(
                    'CÓDIGO MANUAL ALTERNATIVO: $codigoCorto',
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
                  ),
                ],
                pw.SizedBox(height: 10),
                pw.Text(
                  'ID: $codigoQr',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'QR_$nombreElemento',
    );
  }

  void _mostrarDialogoQR(Map<String, dynamic> item) {
    final codigoQr = item['codigo_qr']?.toString().trim();
    if (codigoQr == null || codigoQr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este objeto no tiene un código QR válido configurado.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final String codigoCorto = _obtenerCodigoCorto(item);
    final String nombre = item['nombre']?.toString() ?? 'Elemento';

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
                  Text(
                    'CÓDIGO QR - $nombre',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: QrImageView(
                      data: codigoQr,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  if (codigoCorto.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'CÓDIGO CORTO: $codigoCorto',
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 300,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        _generarYDescargarPDF(nombre, codigoQr, codigoCorto);
                      },
                      icon: const Icon(Icons.picture_as_pdf, color: Colors.black),
                      label: const Text(
                        'DESCARGAR PDF',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
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

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // Toma el codigo_corto si existe en la BD, o genera uno de 5 caracteres desde el codigo_qr
  String _obtenerCodigoCorto(Map<String, dynamic> item) {
    final cortoBD = item['codigo_corto']?.toString().trim();
    if (cortoBD != null && cortoBD.isNotEmpty) {
      return cortoBD.toUpperCase();
    }
    final qr = item['codigo_qr']?.toString().trim() ?? '';
    final limpio = qr.replaceAll('-', '').toUpperCase();
    return limpio.length >= 5 ? limpio.substring(0, 5) : limpio;
  }

  @override
  Widget build(BuildContext context) {
    final String nombreExp = widget.experiencia['nombre']?.toString().toUpperCase() ?? 'EXPERIENCIA';

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

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _agregarElemento,
                icon: const Icon(Icons.add, color: Colors.black),
                label: const Text(
                  'AGREGAR ELEMENTO',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
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

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
                  : _elementos.isEmpty
                      ? const Center(
                          child: Text(
                            'No hay elementos físicos registrados.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _elementos.length,
                          itemBuilder: (context, index) {
                            final item = _elementos[index];
                            final String nombreObj = item['nombre']?.toString() ?? 'Objeto';
                            return Card(
                              color: const Color(0xFF1A1A1A),
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: const Icon(Icons.inventory_2_outlined, color: Colors.cyanAccent),
                                title: Text(
                                  nombreObj,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  item['descripcion']?.toString().isNotEmpty == true
                                      ? item['descripcion'].toString()
                                      : 'Sin descripción adicional',
                                  style: const TextStyle(color: Colors.white54),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.qr_code_2, color: Colors.cyanAccent),
                                      onPressed: () => _mostrarDialogoQR(item),
                                      tooltip: 'Ver y descargar QR de $nombreObj',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      tooltip: 'Eliminar $nombreObj',
                                      onPressed: _isLoading ? null : () => _confirmarEliminarElemento(item),
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
      ),
    );
  }
}