import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/producto_model.dart';
import '../models/cotizacion_model.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import 'package:share_plus/share_plus.dart';

class CrearCotizacionPage extends StatefulWidget {
  final Cotizacion? cotizacion;
  const CrearCotizacionPage({super.key, this.cotizacion});

  @override
  State<CrearCotizacionPage> createState() => _CrearCotizacionPageState();
}

class _CrearCotizacionPageState extends State<CrearCotizacionPage> {
  final clienteController = TextEditingController();
  final telefonoController = TextEditingController();
  final ivaController = TextEditingController(text: '0');
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final cantidadController = TextEditingController(text: '1');


  List<Producto> productos = [];
  int? cotizacionId;

  @override
  void initState() {
    super.initState();
    ivaController.addListener(() {
      setState(() {}); // Esto recalcula el subtotal, iva y total en tiempo real
    });
    if (widget.cotizacion != null) {
      final c = widget.cotizacion!;
      cotizacionId = c.id;
      clienteController.text = c.cliente;
      telefonoController.text = c.telefono;
      ivaController.text = c.iva.toString();
      cargarProductos(cotizacionId!);
    }
  }

  Future<void> cargarProductos(int id) async {
    final db = await DatabaseService.database;
    final productosData = await db.query('productos', where: 'cotizacion_id = ?', whereArgs: [id]);
    setState(() {
      productos = productosData.map((e) => Producto.fromMap(e)).toList();
    });
  }

  void agregarProducto() {
    final descripcion = descripcionController.text.trim();
    final precio = double.tryParse(precioController.text) ?? 0;
    final cantidad = int.tryParse(cantidadController.text) ?? 1;

    if (descripcion.isEmpty || precio <= 0 || cantidad <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❗ Ingresa descripción, precio y cantidad válidos')),
      );
      return;
    }

    setState(() {
      productos.add(Producto(descripcion: descripcion, precio: precio, cantidad: cantidad));
      descripcionController.clear();
      precioController.clear();
      cantidadController.text = '1';
    });
  }


  void editarProducto(int index) {
    final producto = productos[index];
    descripcionController.text = producto.descripcion;
    precioController.text = producto.precio.toString();
    cantidadController.text = producto.cantidad.toString();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Producto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio'),
            ),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                productos[index] = Producto(
                  descripcion: descripcionController.text,
                  precio: double.tryParse(precioController.text) ?? 0,
                  cantidad: int.tryParse(cantidadController.text) ?? 1,
                );
                descripcionController.clear();
                precioController.clear();
                cantidadController.text = '1';
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }


  void eliminarProducto(int index) {
    setState(() => productos.removeAt(index));
  }

  double calcularSubtotal() {
    return productos.fold(0, (sum, p) => sum + (p.precio * p.cantidad));
  }

  double calcularIVA() {
    final subtotal = calcularSubtotal();
    final ivaPorcentaje = double.tryParse(ivaController.text) ?? 0;
    return subtotal * (ivaPorcentaje / 100);
  }

  double calcularTotalFinal() {
    return calcularSubtotal() + calcularIVA();
  }




  Future<bool> solicitarPermisoAlmacenamiento() async {
    var status = await Permission.manageExternalStorage.request();
    if (status.isGranted) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Permiso de almacenamiento denegado')),
    );
    return false;
  }

  Future<void> guardarCotizacion() async {
    if (productos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un producto')),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar guardado'),
        content: const Text('¿Deseas guardar esta cotización y compartir el PDF?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Guardar y Compartir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    bool permiso = await solicitarPermisoAlmacenamiento();
    if (!permiso) return;

    final cliente = clienteController.text;
    final telefono = telefonoController.text;
    final iva = double.tryParse(ivaController.text) ?? 0;
    final fecha = DateTime.now().toIso8601String();
    final db = await DatabaseService.database;

    if (cotizacionId == null) {
      cotizacionId = await db.insert('cotizaciones', {
        'cliente': cliente,
        'telefono': telefono,
        'iva': iva,
        'fecha': fecha,
      });
    } else {
      await db.update('cotizaciones', {
        'cliente': cliente,
        'telefono': telefono,
        'iva': iva,
        'fecha': fecha,
      }, where: 'id = ?', whereArgs: [cotizacionId]);
      await db.delete('productos', where: 'cotizacion_id = ?', whereArgs: [cotizacionId]);
    }

    for (var producto in productos) {
      await db.insert('productos', producto.toMap(cotizacionId!));
    }

    final file = await PDFService.generarCotizacionPDF(
      cliente: cliente,
      telefono: telefono,
      iva: iva,
      productos: productos,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Cotización y PDF guardados exitosamente')),
    );

    if (file != null) {
      await Share.shareXFiles([XFile(file.path)], text: 'Cotización generada');
    }

    Navigator.pop(context, true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(cotizacionId == null ? 'Nueva Cotización' : 'Editar Cotización'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: clienteController,
              decoration: const InputDecoration(labelText: 'Cliente'),
            ),
            TextField(
              controller: telefonoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            TextField(
              controller: ivaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'IVA %'),
            ),
            const SizedBox(height: 20),
            const Text('Agregar Producto', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: cantidadController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            TextField(
              controller: descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            TextField(
              controller: precioController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Precio'),
            ),
            ElevatedButton(onPressed: agregarProducto, child: const Text('Agregar')),
            const SizedBox(height: 20),
            ...productos.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              return ListTile(
                title: Text(p.descripcion),
                subtitle: Text('Cantidad: ${p.cantidad} x \$${p.precio} = ${p.cantidad * p.precio}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => editarProducto(index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => eliminarProducto(index),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subtotal: \$${calcularSubtotal().toStringAsFixed(2)}'),
                Text('IVA (${ivaController.text}%): \$${calcularIVA().toStringAsFixed(2)}'),
                Text(
                  'Total Final: \$${calcularTotalFinal().toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: guardarCotizacion,
              child: const Text('Guardar Cotización y Generar PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
