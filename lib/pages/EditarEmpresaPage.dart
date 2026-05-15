import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/empresa_model.dart';
import '../services/database_service.dart';

class EditarEmpresaPage extends StatefulWidget {
  const EditarEmpresaPage({super.key});

  @override
  State<EditarEmpresaPage> createState() => _EditarEmpresaPageState();
}

class _EditarEmpresaPageState extends State<EditarEmpresaPage> {
  final nombreController = TextEditingController();
  final emailController = TextEditingController();
  final telefonoController = TextEditingController();
  String? logoPath;
  Empresa? empresa;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    cargarDatos();
  }

  Future<void> cargarDatos() async {
    final db = await DatabaseService.database;
    final result = await db.query('empresa', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      empresa = Empresa.fromMap(result.first);
      nombreController.text = empresa!.nombre ?? '';
      emailController.text = empresa!.email ?? '';
      telefonoController.text = empresa!.telefono ?? '';
      logoPath = empresa!.logoPath ?? '';
      setState(() {});
    }
  }

  Future<void> actualizarEmpresa() async {
    final db = await DatabaseService.database;
    final updatedEmpresa = Empresa(
      id: 1,
      nombre: nombreController.text,
      email: emailController.text,
      telefono: telefonoController.text,
      logoPath: logoPath ?? '',
    );

    await db.update('empresa', updatedEmpresa.toMap(), where: 'id = ?', whereArgs: [1]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Empresa actualizada correctamente')),
    );
  }

  Future<void> seleccionarLogo() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        logoPath = image.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Empresa'),
      backgroundColor: Colors.blue),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de la Empresa'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Correo electrónico'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: telefonoController,
              decoration: const InputDecoration(labelText: 'Teléfono'),
            ),
            const SizedBox(height: 20),
            logoPath != null && logoPath!.isNotEmpty
                ? Image.file(File(logoPath!), height: 100)
                : const Text('Sin logo seleccionado'),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: seleccionarLogo,
              child: const Text('Seleccionar Logo'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: actualizarEmpresa,
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}
