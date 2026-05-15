class Empresa {
  final int id;
  final String? nombre;
  final String? email;
  final String? telefono;
  final String? logoPath;

  Empresa({
    required this.id,
    this.nombre,
    this.email,
    this.telefono,
    this.logoPath,
  });

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: map['id'] ?? 1,
      nombre: map['nombre'] as String?,
      email: map['email'] as String?,
      telefono: map['telefono'] as String?,
      logoPath: map['logo_path'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre ?? '',
      'email': email ?? '',
      'telefono': telefono ?? '',
      'logo_path': logoPath ?? '',
    };
  }
}
