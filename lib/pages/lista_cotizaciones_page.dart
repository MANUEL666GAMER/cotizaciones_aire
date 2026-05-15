import 'dart:io';
import 'package:app_cotizacion/pages/crear_cotizacion_page.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/cotizacion_model.dart';
import '../models/producto_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';

class ListaCotizacionesPage extends StatefulWidget {
  const ListaCotizacionesPage({super.key});

  @override
  State<ListaCotizacionesPage> createState() => _ListaCotizacionesPageState();
}

class _ListaCotizacionesPageState extends State<ListaCotizacionesPage> {
  List<Cotizacion> todasCotizaciones = [];
  List<Cotizacion> cotizaciones = [];
  bool cargando = true;
  final TextEditingController busquedaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    busquedaController.addListener(_filtrarCotizaciones);
    obtenerCotizaciones();
  }

  void _filtrarCotizaciones() {
    final query = busquedaController.text.toLowerCase();
    setState(() {
      cotizaciones = todasCotizaciones.where((cot) {
        return cot.cliente.toLowerCase().contains(query) ||
            cot.telefono.toLowerCase().contains(query) ||
            cot.fecha.contains(query);
      }).toList();
    });
  }

  Future<void> eliminarCotizacionesVencidas() async {
    final db = await DatabaseService.database;
    final now = DateTime.now();
    final data = await db.query('cotizaciones');

    for (var cot in data) {
      final fecha = DateTime.parse(cot['fecha'] as String);
      if (now.difference(fecha).inDays > 15) {
        await db.delete('cotizaciones', where: 'id = ?', whereArgs: [cot['id']]);
        await db.delete('productos', where: 'cotizacion_id = ?', whereArgs: [cot['id']]);
      }
    }
  }

  Future<void> obtenerCotizaciones() async {
    final db = await DatabaseService.database;
    await eliminarCotizacionesVencidas();
    final data = await db.query('cotizaciones', orderBy: 'id DESC');

    todasCotizaciones = data.map((e) => Cotizacion.fromMap(e)).toList();
    cotizaciones = List.from(todasCotizaciones);
    setState(() => cargando = false);
  }

  Future<void> eliminarCotizacionManual(int id, int index) async {
    final db = await DatabaseService.database;
    await db.delete('cotizaciones', where: 'id = ?', whereArgs: [id]);
    await db.delete('productos', where: 'cotizacion_id = ?', whereArgs: [id]);
    setState(() {
      cotizaciones.removeAt(index);
      todasCotizaciones.removeWhere((cot) => cot.id == id);
    });
  }

  Future<File?> generarPDF(Cotizacion cotizacion) async {
    final db = await DatabaseService.database;
    final productosData = await db.query('productos', where: 'cotizacion_id = ?', whereArgs: [cotizacion.id]);
    final productos = productosData.map((e) => Producto.fromMap(e)).toList();

    final file = await PDFService.generarCotizacionPDF(
      cliente: cotizacion.cliente,
      telefono: cotizacion.telefono,
      iva: cotizacion.iva,
      productos: productos,
    );

    return file;
  }

  Future<void> reimprimirPDF(Cotizacion cotizacion) async {
    final file = await generarPDF(cotizacion);
    if (file != null) {
      await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al generar el PDF')),
      );
    }
  }

  Future<void> compartirPDF(Cotizacion cotizacion) async {
    final file = await generarPDF(cotizacion);
    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Aquí tienes tu cotización 📄');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Error al generar el PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lista de Cotizaciones'),
        backgroundColor: Colors.blue,
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: busquedaController,
              decoration: const InputDecoration(
                labelText: 'Buscar cotización...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: cotizaciones.isEmpty
                ? const Center(child: Text('No hay cotizaciones registradas.'))
                : ListView.builder(
              itemCount: cotizaciones.length,
              itemBuilder: (context, index) {
                final cot = cotizaciones[index];
                final fechaCotizacion = DateTime.parse(cot.fecha);
                final diasRestantes = 15 - DateTime.now().difference(fechaCotizacion).inDays;
                final textoDiasRestantes = diasRestantes > 0
                    ? 'Días restantes: $diasRestantes días'
                    : '❌ Expirado';
                return Card(
                  color: Colors.grey.shade200,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.grey.shade500),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    title: Text(
                      cot.cliente,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    subtitle: Text(
                      'Teléfono: ${cot.telefono}\n'
                          'Fecha: ${cot.fecha.substring(0, 10)}\n'
                          '$textoDiasRestantes',
                      style: const TextStyle(fontSize: 15),
                    ),


                    trailing: PopupMenuButton<String>(
                      iconSize: 28,
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) async {
                        if (value == 'eliminar') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirmar eliminación'),
                              content: const Text('¿Deseas eliminar esta cotización?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancelar'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm ?? false) {
                            await eliminarCotizacionManual(cot.id!, index);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cotización eliminada correctamente')),
                            );
                          }
                        } else if (value == 'reimprimir') {
                          await reimprimirPDF(cot);
                        } else if (value == 'editar') {
                          final actualizado = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => CrearCotizacionPage(cotizacion: cot)),
                          );
                          if (actualizado == true) obtenerCotizaciones();
                        } else if (value == 'compartir') {
                          await compartirPDF(cot);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'reimprimir',
                          child: ListTile(
                            leading: Icon(Icons.picture_as_pdf, color: Colors.blue),
                            title: Text('Reimprimir PDF'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'compartir',
                          child: ListTile(
                            leading: Icon(Icons.share, color: Colors.green),
                            title: Text('Compartir PDF'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'editar',
                          child: ListTile(
                            leading: Icon(Icons.edit, color: Colors.orange),
                            title: Text('Editar'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'eliminar',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text('Eliminar'),
                          ),
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
