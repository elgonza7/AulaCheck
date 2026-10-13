import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../utiles/layout_base.dart';

// Abre la cámara y devuelve (con Navigator.pop) el texto del primer QR detectado.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  bool yaLeyo = false; // evita cerrar la pantalla dos veces

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: aulaAppBar(context, 'Escanear QR'),
      body: MobileScanner(
        onDetect: (captura) {
          if (yaLeyo) return;
          final codigo = captura.barcodes.firstOrNull?.rawValue;
          if (codigo == null) return;
          yaLeyo = true;
          Navigator.pop(context, codigo);
        },
      ),
    );
  }
}
