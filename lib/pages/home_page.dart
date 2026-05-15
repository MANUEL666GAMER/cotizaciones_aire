import 'package:app_cotizacion/pages/EditarEmpresaPage.dart';
import 'package:flutter/material.dart';
import 'crear_cotizacion_page.dart';
import 'lista_cotizaciones_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cotizaciones Air Control'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CrearCotizacionPage()));
              },
              child: const Text('Nueva Cotización'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {

                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ListaCotizacionesPage()));
              },
              child: const Text('Ver Cotizaciones'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const EditarEmpresaPage()));
              },
              child: const Text('Editar Empresa'),
            ),


          ],
        ),
      ),
    );
  }
}
