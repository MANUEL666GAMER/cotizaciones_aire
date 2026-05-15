import 'producto_model.dart';

class Cotizacion {
  int? id;
  String cliente;
  String telefono;
  double iva;
  String fecha;
  List<Producto> productos;

  Cotizacion({
    this.id,
    required this.cliente,
    required this.telefono,
    required this.iva,
    required this.fecha,
    this.productos = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cliente': cliente,
      'telefono': telefono,
      'iva': iva,
      'fecha': fecha,
    };
  }

  factory Cotizacion.fromMap(Map<String, dynamic> map) {
    return Cotizacion(
      id: map['id'] as int?,
      cliente: map['cliente'] ?? '',
      telefono: map['telefono'] ?? '',
      iva: (map['iva'] ?? 0).toDouble(),
      fecha: map['fecha'] ?? '',
    );
  }
}
