import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../items/items_provider.dart';
import '../items/item_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Scan QR / Barcode",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.zap),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(LucideIcons.camera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isDisposed) {
                final code = barcodes.first.rawValue;
                if (code != null) {
                  // Prevent reuse until handling is done or not found
                  // _isDisposed = true; // Wait! Only dispose if we pop.

                  // Check if item exists
                  final itemsProvider = Provider.of<ItemsProvider>(
                    context,
                    listen: false,
                  );
                  final item = itemsProvider.findByCode(code);

                  if (item != null) {
                    _isDisposed = true; // Now we can dispose/lock
                    HapticFeedback.mediumImpact();
                    // Navigate to Detail
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ItemDetailScreen(item: item),
                      ),
                    );
                  } else {
                    // Show error but let them keep scanning?
                    // Maybe pause camera briefly?
                    // For now just SnackBar
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Barang tidak ditemukan: $code"),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              }
            },
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertTriangle,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text('Camera Error: ${error.errorCode}'),
                  ],
                ),
              );
            },
          ),
          // Overlay
          Container(
            decoration: ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: Colors.blueAccent,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          // Helper Text
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Arahkan kamera ke kode QR / Barcode",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple overlay shape logic if library one is not available or we prefer custom.
// Actually, MobileScanner does not provide this shape built-in in older versions,
// but let's check if we can write a simple one or if we should just use a Container with borders.
// For now, I'll implement a custom CustomPainter or similar to be safe,
// OR just imports relevant shape if I knew the package version.
// To be safe and "smart", I will write a CustomPainter class at the bottom of this file.

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 10.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 80),
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path isQuery = Path();
    Path path = Path();
    isQuery.addRect(rect);

    double cutOutWidth = cutOutSize;
    double cutOutHeight = cutOutSize;

    final leftOffset = (rect.width - cutOutWidth) / 2;
    final topOffset = (rect.height - cutOutHeight) / 2;

    final cutOutRect = Rect.fromLTWH(
      leftOffset,
      topOffset,
      cutOutWidth,
      cutOutHeight,
    );

    path.addRect(cutOutRect);
    return Path.combine(PathOperation.difference, isQuery, path);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;

    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;
    final cutOutLeft = (width - cutOutWidth) / 2;
    final cutOutTop = (height - cutOutHeight) / 2;

    final backgroundPaint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Draw background with hole
    final backgroundPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cutOutLeft, cutOutTop, cutOutWidth, cutOutHeight),
          Radius.circular(borderRadius),
        ),
      );

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw corners
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft, cutOutTop + borderLength)
        ..lineTo(cutOutLeft, cutOutTop + borderRadius)
        ..quadraticBezierTo(
          cutOutLeft,
          cutOutTop,
          cutOutLeft + borderRadius,
          cutOutTop,
        )
        ..lineTo(cutOutLeft + borderLength, cutOutTop),
      borderPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutWidth - borderLength, cutOutTop)
        ..lineTo(cutOutLeft + cutOutWidth - borderRadius, cutOutTop)
        ..quadraticBezierTo(
          cutOutLeft + cutOutWidth,
          cutOutTop,
          cutOutLeft + cutOutWidth,
          cutOutTop + borderRadius,
        )
        ..lineTo(cutOutLeft + cutOutWidth, cutOutTop + borderLength),
      borderPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(
          cutOutLeft + cutOutWidth,
          cutOutTop + cutOutHeight - borderLength,
        )
        ..lineTo(
          cutOutLeft + cutOutWidth,
          cutOutTop + cutOutHeight - borderRadius,
        )
        ..quadraticBezierTo(
          cutOutLeft + cutOutWidth,
          cutOutTop + cutOutHeight,
          cutOutLeft + cutOutWidth - borderRadius,
          cutOutTop + cutOutHeight,
        )
        ..lineTo(
          cutOutLeft + cutOutWidth - borderLength,
          cutOutTop + cutOutHeight,
        ),
      borderPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + borderLength, cutOutTop + cutOutHeight)
        ..lineTo(cutOutLeft + borderRadius, cutOutTop + cutOutHeight)
        ..quadraticBezierTo(
          cutOutLeft,
          cutOutTop + cutOutHeight,
          cutOutLeft,
          cutOutTop + cutOutHeight - borderRadius,
        )
        ..lineTo(cutOutLeft, cutOutTop + cutOutHeight - borderLength),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
