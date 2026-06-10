// Stub implementation for web platform
import 'package:flutter/material.dart';

class QRView extends StatelessWidget {
  const QRView({
    super.key,
    this.onQRViewCreated,
    this.overlay,
  });

  final Function(QRViewController)? onQRViewCreated;
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'QR Scanner not available on web',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class QRViewController {
  void dispose() {}
  Stream<Barcode> get scannedDataStream => const Stream.empty();
}

class Barcode {
  final String? code;
  const Barcode({this.code});
}

class QrScannerOverlayShape extends StatelessWidget {
  const QrScannerOverlayShape({
    super.key,
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  @override
  Widget build(BuildContext context) {
    return Container(); // Stub implementation
  }
}
