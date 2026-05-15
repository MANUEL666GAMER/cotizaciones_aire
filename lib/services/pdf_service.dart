import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import '../models/producto_model.dart';
import '../services/database_service.dart';

class PDFService {
  static Future<File?> generarCotizacionPDF({
    required String cliente,
    required String telefono,
    required double iva,
    required List<Producto> productos,
  }) async {
    if (Platform.isAndroid) {
      bool permiso = await _solicitarPermiso();
      if (!permiso) return null;
    }

    final db = await DatabaseService.database;
    final empresa = await db.query('empresa', limit: 1);
    final nombreEmpresa = empresa.first['nombre'] ?? 'EMPRESA';
    final correoEmpresa = empresa.first['email'] ?? 'ejemplo@correo.com';
    final telefonoEmpresa = empresa.first['telefono'].toString() ?? '';
    final logoPath = empresa.first['logo_path'] ?? '';

    pw.ImageProvider logoImage;
    if (logoPath != null && logoPath.toString().isNotEmpty) {
      logoImage = pw.MemoryImage(File(logoPath.toString()).readAsBytesSync());
    } else {
      final ByteData bytes = await rootBundle.load('assets/Logo.png');
      logoImage = pw.MemoryImage(bytes.buffer.asUint8List());
    }

    final pdf = pw.Document();

    double subtotal = productos.fold(0, (sum, p) => sum + p.precio);
    double ivaMonto = subtotal * (iva / 100);
    double total = subtotal + ivaMonto;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Image(logoImage, width: 100),
                    pw.SizedBox(height: 10),
                    pw.Text('EMPRESA: $nombreEmpresa'),
                    pw.Text('CORREO: $correoEmpresa'),
                    pw.Text('TELÉFONO: $telefonoEmpresa'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('COTIZACIÓN', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 5),
                    pw.Text('CLIENTE:'),
                    pw.Text('Nombre: $cliente'),
                    pw.Text('Teléfono: $telefono'),
                    pw.Text('Fecha: ${DateTime.now().toLocal().toString().split(' ')[0]}'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Cantidad', 'Descripción', 'Precio Unitario', 'Total'],
              data: productos.map((p) => [
                p.cantidad,
                p.descripcion,
                '\$${p.precio.toStringAsFixed(2)}',
                '\$${p.total.toStringAsFixed(2)}',
              ]).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              width: double.infinity,
              color: PdfColors.lightBlue,
              padding: const pw.EdgeInsets.all(8),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Si requiere factura el subtotal es + IVA'),
                      pw.Text('Vigencia de cotización 15 días'),
                      pw.Text('Precios sujetos a cambio sin previo aviso'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('SUBTOTAL: \$${subtotal.toStringAsFixed(2)}'),
                      pw.Text('IVA (${iva.toStringAsFixed(0)}%): \$${ivaMonto.toStringAsFixed(2)}'),
                      pw.Text('TOTAL: \$${total.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    Directory baseDir = Platform.isAndroid
        ? Directory('/storage/emulated/0/Cotizaciones')
        : await getApplicationDocumentsDirectory();

    if (!await baseDir.exists()) await baseDir.create(recursive: true);

    final file = File(path.join(
      baseDir.path,
      'Cotizacion_${cliente}_${DateTime.now().toLocal().toString().split(' ')[0]}.pdf',
    ));
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static Future<bool> _solicitarPermiso() async {
    if (await Permission.manageExternalStorage.isGranted) return true;
    if (await Permission.manageExternalStorage.request().isGranted) return true;
    if (await Permission.storage.isGranted) return true;
    if (await Permission.storage.request().isGranted) return true;
    return false;
  }
}
