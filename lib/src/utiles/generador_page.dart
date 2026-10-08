
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'responsive.dart';

class GeneradorPage extends StatefulWidget {
  const GeneradorPage({super.key});

  @override
  State<GeneradorPage> createState() => _GeneradorPageState();
}

class _GeneradorPageState extends State<GeneradorPage> {
  // Key global para capturar el widget de QR y convertirlo en imagen.
  final GlobalKey qrKey = GlobalKey();
  String qrData = '';
  final TextEditingController _controller = TextEditingController();

  // Función para guardar el QR en la galería/disco
  Future<void> _saveQR() async {
    try {
      if (qrData.isEmpty) {
        throw Exception("No hay un código QR para guardar.");
      }

      // 1. Renderizar el widget como imagen
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // 2. Usar image_gallery_saver para guardar
      final result = await ImageGallerySaverPlus.saveImage(
        pngBytes,
        quality: 100,
        name: "qr_generado_${DateTime.now().millisecondsSinceEpoch}",
      );

      // 3. Mostrar mensaje de éxito
      if (result['isSuccess'] == true) {
        _showSnackbar("¡QR Guardado!", Colors.green);
      } else {
        throw Exception("Fallo al guardar la imagen.");
      }
    } catch (e) {
      _showSnackbar("Error al guardar: ${e.toString()}", Colors.red);
    }
  }

  // Helper para mostrar mensajes temporales
  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(responsive.wp(4)), // adaptable
      child: Column(
        children: [
          // 1. Campo de texto
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Introduce Texto o URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(responsive.dp(1.2)),
                ),
              ),
              prefixIcon: Icon(Icons.link, size: responsive.dp(2.2)),
            ),
            maxLines: 3,
          ),
          SizedBox(height: responsive.hp(2)),

          // 2. Botón de Generar
          ElevatedButton.icon(
            icon: Icon(Icons.refresh, size: responsive.dp(2.2)),
            label: Text(
              'Generar QR',
              style: TextStyle(fontSize: responsive.dp(1.7)),
            ),
            onPressed: () {
              setState(() {
                qrData = _controller.text.trim();
              });
            },
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, responsive.hp(6)),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.dp(1)),
              ),
            ),
          ),
          SizedBox(height: responsive.hp(3)),

          // 3. Visualización del QR
          if (qrData.isNotEmpty) ...[
            RepaintBoundary(
              key: qrKey,
              child: QrImageView(
                data: qrData,
                version: QrVersions.auto,
                size: responsive.wp(responsive.isTablet ? 40 : 60),
                gapless: true,
                embeddedImage: const AssetImage('assets/logo.jpg'),
                embeddedImageStyle: QrEmbeddedImageStyle(
                  size: Size(
                    responsive.wp(responsive.isTablet ? 8 : 10),
                    responsive.wp(responsive.isTablet ? 8 : 10),
                  ),
                ),
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(height: responsive.hp(3)),

            ElevatedButton.icon(
              icon: Icon(Icons.download, size: responsive.dp(2.2)),
              label: Text(
                'Descargar QR',
                style: TextStyle(fontSize: responsive.dp(1.7)),
              ),
              onPressed: _saveQR,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, responsive.hp(6)),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.dp(1)),
                ),
              ),
            ),
          ] else
            // Contenedor placeholder
            Container(
              height: responsive.wp(responsive.isTablet ? 40 : 60),
              width: responsive.wp(responsive.isTablet ? 40 : 60),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey.shade300,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(responsive.dp(1.2)),
              ),
              child: Center(
                child: Text(
                  'Ingresa texto o URL\ny haz clic en Generar',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: responsive.dp(1.6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
