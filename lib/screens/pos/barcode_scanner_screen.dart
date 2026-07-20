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

  String? _candidateBarcode;
  int _matchingDetections = 0;
  DateTime? _candidateFirstSeen;
  DateTime? _lastDetectionTime;

  String _scanStatus = 'Align the product barcode inside the box.';
  Color _statusColor = Colors.white;

  static const Duration _cameraWarmUp = Duration(milliseconds: 700);
  static const Duration _requiredStableTime = Duration(milliseconds: 900);
  static const Duration _maximumDetectionGap = Duration(milliseconds: 500);
  static const int _requiredMatchingDetections = 4;

  late final DateTime _scannerReadyAt;

  @override
  void initState() {
    super.initState();

    _scannerReadyAt = DateTime.now().add(_cameraWarmUp);

    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
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

  String? _extractBarcode(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  void _resetCandidate({
    String status = 'Align the product barcode inside the box.',
  }) {
    _candidateBarcode = null;
    _matchingDetections = 0;
    _candidateFirstSeen = null;
    _lastDetectionTime = null;

    if (!mounted || hasScanned) return;

    setState(() {
      _scanStatus = status;
      _statusColor = Colors.white;
    });
  }

  void handleBarcode(BarcodeCapture capture) {
    if (hasScanned || capture.barcodes.isEmpty) return;

    final now = DateTime.now();

    if (now.isBefore(_scannerReadyAt)) {
      if (mounted && _scanStatus != 'Preparing camera...') {
        setState(() {
          _scanStatus = 'Preparing camera...';
          _statusColor = Colors.white70;
        });
      }
      return;
    }

    final barcodeValue = _extractBarcode(capture);
    if (barcodeValue == null) return;

    final bool detectionGapTooLong =
        _lastDetectionTime != null &&
        now.difference(_lastDetectionTime!) > _maximumDetectionGap;

    if (_candidateBarcode != barcodeValue || detectionGapTooLong) {
      _candidateBarcode = barcodeValue;
      _matchingDetections = 1;
      _candidateFirstSeen = now;
      _lastDetectionTime = now;

      if (mounted) {
        setState(() {
          _scanStatus = 'Barcode detected. Hold steady...';
          _statusColor = Colors.amber;
        });
      }
      return;
    }

    _matchingDetections++;
    _lastDetectionTime = now;

    final stableDuration = now.difference(_candidateFirstSeen!);
    final progress =
        (stableDuration.inMilliseconds / _requiredStableTime.inMilliseconds)
            .clamp(0.0, 1.0);

    if (mounted) {
      setState(() {
        _scanStatus = 'Hold steady... ${(progress * 100).toStringAsFixed(0)}%';
        _statusColor = Colors.amber;
      });
    }

    final bool enoughDetections =
        _matchingDetections >= _requiredMatchingDetections;
    final bool stableLongEnough = stableDuration >= _requiredStableTime;

    if (!enoughDetections || !stableLongEnough) return;

    hasScanned = true;

    if (mounted) {
      setState(() {
        _scanStatus = 'Barcode confirmed!';
        _statusColor = Colors.greenAccent;
      });
    }

    unawaited(controller.stop());

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      Navigator.of(context).pop(barcodeValue);
    });
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
      _resetCandidate(status: 'Refocusing camera...');
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
                  borderColor: hasScanned
                      ? Colors.greenAccent
                      : _candidateBarcode != null
                      ? Colors.amber
                      : Colors.green,
                  borderRadius: 12,
                  borderLength: 35,
                  borderWidth: 4,
                  cutOutSize: MediaQuery.of(context).size.width * 0.75,
                ),
              ),
            ),
          ),
          Positioned(
            left: 25,
            right: 25,
            bottom: 70,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _statusColor.withValues(alpha: 0.75)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!hasScanned && _candidateBarcode != null) ...[
                    SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _statusColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else if (hasScanned) ...[
                    Icon(Icons.check_circle, color: _statusColor, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      _scanStatus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    unawaited(controller.dispose());
    super.dispose();
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
