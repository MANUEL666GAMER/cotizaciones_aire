class Producto {
  String descripcion;
  double precio;
  int cantidad;

  Producto({required this.descripcion, required this.precio, required this.cantidad});

  Map<String, dynamic> toMap(int cotizacionId) {
    return {
      'cotizacion_id': cotizacionId,
      'descripcion': descripcion,
      'precio': precio,
      'cantidad': cantidad,
    };
  }

  static Producto fromMap(Map<String, dynamic> map) {
    return Producto(
      descripcion: map['descripcion'],
      precio: map['precio'],
      cantidad: map['cantidad'],
    );
  }

  double get total => precio * cantidad;
}
