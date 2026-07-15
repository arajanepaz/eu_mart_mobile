import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  late final MobileScannerController controller;

  bool hasScanned = false;

  @override
  void initState() {
    super.initState();

    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.itf14,
        BarcodeFormat.codabar,
      ],
    );
  }

  void handleBarcode(BarcodeCapture capture) {
    if (hasScanned || capture.barcodes.isEmpty) return;

    String? barcodeValue;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        barcodeValue = value;
        break;
      }
    }

    if (barcodeValue == null) return;

    hasScanned = true;

    if (!mounted) return;

    Navigator.of(context).pop(barcodeValue);
  }

  Future<void> toggleFlash() async {
    try {
      await controller.toggleTorch();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi mabuksan ang flash: $error')),
      );
    }
  }

  Future<void> switchCamera() async {
    try {
      await controller.switchCamera();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hindi mapalitan ang camera: $error')),
      );
    }
  }

  Widget buildScannerError(BuildContext context, MobileScannerException error) {
    String message;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message =
            'Hindi pinayagan ang camera.\n\n'
            'Pumunta sa App Info → Permissions → Camera → Allow.';
        break;

      case MobileScannerErrorCode.unsupported:
        message = 'Hindi supported ng device na ito ang barcode scanner.';
        break;

      case MobileScannerErrorCode.controllerUninitialized:
        message =
            'Hindi pa handa ang camera.\n'
            'Bumalik at buksan ulit ang scanner.';
        break;

      case MobileScannerErrorCode.controllerDisposed:
        message =
            'Naisara na ang camera controller.\n'
            'Bumalik at buksan ulit ang scanner.';
        break;

      default:
        message =
            'May problema sa camera.\n\n'
            '${error.errorDetails?.message ?? error.errorCode.name}';
    }

    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.camera_alt_outlined, size: 70, color: Colors.white),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Bumalik'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Flash',
            icon: const Icon(Icons.flash_on),
            onPressed: toggleFlash,
          ),
          IconButton(
            tooltip: 'Switch Camera',
            icon: const Icon(Icons.cameraswitch),
            onPressed: switchCamera,
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: handleBarcode,
            onDetectError: (error, stackTrace) {
              debugPrint('Barcode detection error: $error');
              debugPrintStack(stackTrace: stackTrace);
            },
            errorBuilder: buildScannerError,
            fit: BoxFit.cover,
            tapToFocus: true,
          ),

          IgnorePointer(
            child: Container(
              decoration: ShapeDecoration(
                shape: BarcodeScannerOverlayShape(
                  borderColor: Colors.green,
                  borderRadius: 12,
                  borderLength: 35,
                  borderWidth: 4,
                  cutOutSize: MediaQuery.of(context).size.width * 0.75,
                ),
              ),
            ),
          ),

          const Positioned(
            left: 25,
            right: 25,
            bottom: 70,
            child: Text(
              'Align the product barcode inside the box.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: Colors.black, blurRadius: 8)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await controller.dispose();
  }
}

class BarcodeScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const BarcodeScannerOverlayShape({
    required this.borderColor,
    required this.borderWidth,
    required this.borderLength,
    required this.borderRadius,
    required this.cutOutSize,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..addRect(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final scanRect = Rect.fromCenter(
      center: rect.center,
      width: cutOutSize,
      height: cutOutSize * 0.55,
    );

    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.55);

    final overlayPath = Path()
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(scanRect, Radius.circular(borderRadius)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

    final left = scanRect.left;
    final right = scanRect.right;
    final top = scanRect.top;
    final bottom = scanRect.bottom;

    canvas.drawLine(
      Offset(left, top + borderLength),
      Offset(left, top),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left, top),
      Offset(left + borderLength, top),
      borderPaint,
    );

    canvas.drawLine(
      Offset(right - borderLength, top),
      Offset(right, top),
      borderPaint,
    );

    canvas.drawLine(
      Offset(right, top),
      Offset(right, top + borderLength),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left, bottom - borderLength),
      Offset(left, bottom),
      borderPaint,
    );

    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + borderLength, bottom),
      borderPaint,
    );

    canvas.drawLine(
      Offset(right - borderLength, bottom),
      Offset(right, bottom),
      borderPaint,
    );

    canvas.drawLine(
      Offset(right, bottom),
      Offset(right, bottom - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) => this;
}
