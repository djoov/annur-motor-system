import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../core/theme.dart';
import '../items/items_provider.dart';
import '../items/item_detail_screen.dart';
import '../items/item_form_screen.dart';
import '../pos/pos_provider.dart';
import '../../ui/stock_badge.dart';
import '../pos/models/pos_models.dart';
import '../auth/auth_provider.dart';

class ScanScreen extends StatefulWidget {
  /// If true, just return the scanned code without opening the smart bottom sheet
  final bool returnCodeOnly;

  const ScanScreen({Key? key, this.returnCodeOnly = false}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isProcessing = false;
  bool _isTorchOn = false;
  late AnimationController _animController;
  late Animation<double> _laserAnimation;

  final currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    // Laser animation sweeping up & down
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue?.trim();
    if (code == null || code.isEmpty) return;

    _handleScannedCode(code);
  }

  void _handleScannedCode(String code) {
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    // If caller only needs the raw code string (e.g. from Form Barang)
    if (widget.returnCodeOnly) {
      Navigator.pop(context, code);
      return;
    }

    final itemsProvider = Provider.of<ItemsProvider>(context, listen: false);
    final posProvider = Provider.of<PosProvider>(context, listen: false);

    // Find item by code or barcode
    Item? foundItem = itemsProvider.findByCode(code);

    // Also check posProvider items as backup
    if (foundItem == null) {
      try {
        foundItem = posProvider.filteredItems.firstWhere(
          (i) => i.code.trim().toLowerCase() == code.toLowerCase(),
        );
      } catch (_) {}
    }

    if (foundItem != null) {
      _showFoundItemSheet(foundItem);
    } else {
      _showNotFoundSheet(code);
    }
  }

  // =========================================================================
  // RESULT SHEETS
  // =========================================================================
  void _resumeScanning() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showFoundItemSheet(Item item) {
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    final meta = [
      if (item.code.isNotEmpty) item.code,
      item.category ?? 'Umum',
      if (item.locationDisplay != null && item.locationDisplay!.isNotEmpty)
        "Rak ${item.locationDisplay}",
    ].join(" · ");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: AppColors.muted,
                        child: hasImage
                            ? Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  LucideIcons.package,
                                  color: AppColors.mutedForeground,
                                  size: 28,
                                ),
                              )
                            : const Icon(
                                LucideIcons.package,
                                color: AppColors.mutedForeground,
                                size: 28,
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            meta,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StockBadge(item.stockDisplay),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Harga jual",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(
                            currencyFormat.format(item.sellPrice),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isAdmin)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Modal",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.mutedForeground,
                            ),
                          ),
                          Text(
                            currencyFormat.format(item.buyPrice),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.mutedForeground,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: item.stockDisplay <= 0
                        ? null
                        : () {
                            Navigator.pop(ctx);
                            final added = Provider.of<PosProvider>(
                              context,
                              listen: false,
                            ).addToCart(item);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  added
                                      ? "${item.name} masuk keranjang Kasir"
                                      : "Stok ${item.name} di keranjang sudah maksimal",
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                    icon: const Icon(LucideIcons.shoppingCart, size: 20),
                    label: Text(
                      item.stockDisplay <= 0
                          ? "Stok habis"
                          : "Masukkan ke Keranjang",
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ItemDetailScreen(item: item),
                            ),
                          );
                        },
                        child: const Text("Detail Barang"),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(LucideIcons.scanLine, size: 18),
                        label: const Text("Scan lagi"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _resumeScanning());
  }

  void _showNotFoundSheet(String code) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  LucideIcons.search,
                  size: 40,
                  color: AppColors.mutedForeground,
                ),
                const SizedBox(height: 12),
                const Text(
                  "Barang belum terdaftar",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kode $code belum ada di daftar barang.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.mutedForeground,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ItemFormScreen(initialCode: code),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.plus, size: 20),
                    label: const Text("Daftarkan Barang Baru"),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(LucideIcons.scanLine, size: 18),
                  label: const Text("Scan lagi"),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => _resumeScanning());
  }

  // =========================================================================
  // MANUAL BARCODE INPUT MODAL
  // =========================================================================
  void _showManualInputDialog() {
    final textCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(LucideIcons.keyboard, color: AppColors.primary, size: 20),
              SizedBox(width: 10),
              Text("Ketik Kode Manual", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Masukkan nomor barcode atau SKU jika stiker kemasan kotor/rusak:",
                style: TextStyle(fontSize: 12, color: AppColors.mutedForeground),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: textCtrl,
                autofocus: true,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Contoh: 8992775215012 / OLI-MPX2",
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal", style: TextStyle(color: AppColors.mutedForeground)),
            ),
            ElevatedButton(
              onPressed: () {
                final code = textCtrl.text.trim();
                Navigator.pop(ctx);
                if (code.isNotEmpty) {
                  _handleScannedCode(code);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Cari Barang", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const double cutOutSize = 260.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertTriangle, size: 54, color: AppColors.warning),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak Dapat Mengakses Kamera',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan izin kamera sudah diberikan: ${error.errorCode}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Cutout Overlay Mask
          Container(
            decoration: const ShapeDecoration(
              shape: QrScannerOverlayShape(
                borderColor: AppColors.brandYellow,
                borderRadius: 16,
                borderLength: 36,
                borderWidth: 6,
                cutOutSize: cutOutSize,
                overlayColor: Color.fromRGBO(0, 0, 0, 160),
              ),
            ),
          ),

          // 3. Laser Animation Line
          Center(
            child: SizedBox(
              width: cutOutSize - 20,
              height: cutOutSize - 20,
              child: AnimatedBuilder(
                animation: _laserAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: LaserScanPainter(progress: _laserAnimation.value),
                  );
                },
              ),
            ),
          ),

          // 4. Header Bar (Back, Title, Flashlight, Flip Camera)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Text(
                    widget.returnCodeOnly ? "Scan Barcode" : "Cek Harga",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  Row(
                    children: [
                      // Torch Toggle
                      Container(
                        decoration: BoxDecoration(
                          color: _isTorchOn
                              ? AppColors.warningStrong.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isTorchOn ? LucideIcons.zapOff : LucideIcons.zap,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            _controller.toggleTorch();
                            setState(() => _isTorchOn = !_isTorchOn);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Camera Switch
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                          onPressed: () => _controller.switchCamera(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction & Manual Input Button at Bottom
          Positioned(
            bottom: 36,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.scan, color: AppColors.brandYellow, size: 16),
                      SizedBox(width: 8),
                      Text(
                        "Arahkan kamera ke barcode barang",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Manual Input Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showManualInputDialog,
                    icon: const Icon(LucideIcons.keyboard, color: Colors.white, size: 18),
                    label: const Text(
                      "Ketik Kode Manual",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// LASER SCAN ANIMATION PAINTER
// =========================================================================
class LaserScanPainter extends CustomPainter {
  final double progress;

  LaserScanPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * progress;

    // Laser Line Paint
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          AppColors.brandYellow.withValues(alpha: 0.8),
          AppColors.brandYellow,
          AppColors.brandYellow.withValues(alpha: 0.8),
          Colors.transparent,
        ],
        stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 2, size.width, 4))
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    // Subtle Glow Aura
    final glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.brandYellow.withValues(alpha: 0.0),
          AppColors.brandYellow.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, y - 18, size.width, 18))
      ..style = PaintingStyle.fill;

    canvas.drawRect(Rect.fromLTWH(0, y - 18, size.width, 18), glowPaint);
  }

  @override
  bool shouldRepaint(covariant LaserScanPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// =========================================================================
// CUSTOM QR SCANNER OVERLAY SHAPE
// =========================================================================
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.blueAccent,
    this.borderWidth = 6.0,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 160),
    this.borderRadius = 16,
    this.borderLength = 36,
    this.cutOutSize = 260,
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
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round;

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

    // Draw Rounded Corner Accents
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft, cutOutTop + borderLength)
        ..lineTo(cutOutLeft, cutOutTop + borderRadius)
        ..quadraticBezierTo(cutOutLeft, cutOutTop, cutOutLeft + borderRadius, cutOutTop)
        ..lineTo(cutOutLeft + borderLength, cutOutTop),
      borderPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutWidth - borderLength, cutOutTop)
        ..lineTo(cutOutLeft + cutOutWidth - borderRadius, cutOutTop)
        ..quadraticBezierTo(cutOutLeft + cutOutWidth, cutOutTop, cutOutLeft + cutOutWidth, cutOutTop + borderRadius)
        ..lineTo(cutOutLeft + cutOutWidth, cutOutTop + borderLength),
      borderPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + cutOutWidth, cutOutTop + cutOutHeight - borderLength)
        ..lineTo(cutOutLeft + cutOutWidth, cutOutTop + cutOutHeight - borderRadius)
        ..quadraticBezierTo(cutOutLeft + cutOutWidth, cutOutTop + cutOutHeight, cutOutLeft + cutOutWidth - borderRadius, cutOutTop + cutOutHeight)
        ..lineTo(cutOutLeft + cutOutWidth - borderLength, cutOutTop + cutOutHeight),
      borderPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(cutOutLeft + borderLength, cutOutTop + cutOutHeight)
        ..lineTo(cutOutLeft + borderRadius, cutOutTop + cutOutHeight)
        ..quadraticBezierTo(cutOutLeft, cutOutTop + cutOutHeight, cutOutLeft, cutOutTop + cutOutHeight - borderRadius)
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
