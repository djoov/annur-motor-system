import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme.dart';

/// Full-screen logo-navy layout for login/register (Livin-style):
/// logo on a white tile, faint hexagon pattern from the logo shape,
/// white input fields and a yellow primary button.
class AuthShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;
  final bool showBack;

  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.showBack = false,
  });

  /// Local theme so fields, buttons, links and snackbars read well on navy.
  static ThemeData _onNavy(ThemeData base) {
    final ff = base.textTheme.bodyMedium?.fontFamily;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: AppColors.surface,
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(AppColors.brandYellow, 2),
        errorBorder: border(AppColors.destructiveBorder, 2),
        focusedErrorBorder: border(AppColors.destructiveBorder, 2),
        errorStyle: TextStyle(
          fontFamily: ff,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.destructiveBorder,
        ),
        helperStyle: TextStyle(
          fontFamily: ff,
          fontSize: 12,
          color: Colors.white.withValues(alpha: 0.7),
        ),
        floatingLabelStyle: TextStyle(
          fontFamily: ff,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandYellow,
          foregroundColor: AppColors.brandNavy,
          disabledBackgroundColor: AppColors.brandYellow.withValues(alpha: 0.5),
          disabledForegroundColor: AppColors.brandNavy.withValues(alpha: 0.7),
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: TextStyle(
            fontFamily: ff,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandYellow,
          minimumSize: const Size(48, 48),
          textStyle: TextStyle(
            fontFamily: ff,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandNavy,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        backgroundColor: AppColors.surface,
        contentTextStyle: TextStyle(
          fontFamily: ff,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.foreground,
        ),
        actionTextColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 900;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Theme(
        data: _onNavy(Theme.of(context)),
        child: Scaffold(
          backgroundColor: AppColors.brandNavy,
          body: Stack(
            children: [
              const Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _HexPatternPainter()),
                ),
              ),
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, wide ? 48 : 32, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Brand(),
                          SizedBox(height: wide ? 48 : 40),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ...children,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (showBack)
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      tooltip: "Kembali",
                      icon: const Icon(LucideIcons.arrowLeft,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // White tile so the dark hexagon logo stands out on navy
        Container(
          width: 96,
          height: 96,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandYellow.withValues(alpha: 0.18),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Image.asset('assets/logo_app_new.png', fit: BoxFit.contain),
        ),
        const SizedBox(height: 16),
        const Text(
          "Annur Motor",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          "Kasir & stok bengkel",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

/// Faint pointy-top hexagon grid echoing the logo shape.
class _HexPatternPainter extends CustomPainter {
  const _HexPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const r = 34.0; // hexagon radius
    final w = math.sqrt(3) * r;
    const vStep = 1.5 * r;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    Path hex(Offset c) {
      final p = Path();
      for (var i = 0; i < 6; i++) {
        final a = math.pi / 180 * (60 * i - 90);
        final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
        i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
      }
      return p..close();
    }

    var row = 0;
    for (var y = 0.0; y < size.height + r; y += vStep, row++) {
      final offset = row.isOdd ? w / 2 : 0.0;
      for (var x = -w; x < size.width + w; x += w) {
        canvas.drawPath(hex(Offset(x + offset, y)), paint);
      }
    }

    // Soft yellow glow behind the logo area
    final glow = Paint()
      ..shader = RadialGradient(
        colors: [
          AppColors.brandYellow.withValues(alpha: 0.10),
          AppColors.brandYellow.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width / 2, 110),
        radius: 220,
      ));
    canvas.drawRect(Offset.zero & size, glow);
  }

  @override
  bool shouldRepaint(covariant _HexPatternPainter oldDelegate) => false;
}

/// Maps Firebase auth error codes to short Indonesian messages.
String authErrorMessage(Object e, {String fallback = "Terjadi kesalahan"}) {
  final s = e.toString();
  if (s.contains("user-not-found") || s.contains("invalid-credential")) {
    return "Email atau password salah.";
  }
  if (s.contains("wrong-password")) return "Password salah.";
  if (s.contains("invalid-email")) return "Format email tidak valid.";
  if (s.contains("email-already-in-use")) {
    return "Email sudah terdaftar. Silakan masuk.";
  }
  if (s.contains("weak-password")) return "Password terlalu lemah.";
  if (s.contains("too-many-requests")) {
    return "Terlalu banyak percobaan. Coba lagi beberapa menit lagi.";
  }
  if (s.contains("network-request-failed")) {
    return "Tidak ada koneksi internet.";
  }
  return fallback;
}
