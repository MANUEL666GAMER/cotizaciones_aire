import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const CotizacionesApp());
}

class CotizacionesApp extends StatelessWidget {
  const CotizacionesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cotizador Aire',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
