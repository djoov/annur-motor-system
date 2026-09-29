import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Annur's own duotone icon set: brand-blue outline + logo-yellow accent.
///
/// Drawn with [CustomPainter] on a 24×24 grid (no image assets), so icons stay
/// sharp at any size and can ship through Shorebird patches.
enum DuoIcons {
  scan,
  users,
  chart,
  stockRequest,
  grid,
  history,
  wallet,
  package,
  category,
  lowStock,
  opname,
  supplier,
  purchase,
  import,
  userAdmin,
  user,
  settings,
}

class DuoIcon extends StatelessWidget {
  final DuoIcons icon;
  final double size;

  /// Color behind the icon; used to "cut out" overlapping shapes.
  final Color background;

  const DuoIcon(
    this.icon, {
    super.key,
    this.size = 24,
    this.background = AppColors.primarySoft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _DuoIconPainter(icon, background)),
    );
  }
}

/// Rounded pale-blue tile holding a [DuoIcon] — the standard menu button face.
class DuoIconTile extends StatelessWidget {
  final DuoIcons icon;
  final double size;

  const DuoIconTile(this.icon, {super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      alignment: Alignment.center,
      child: DuoIcon(icon, size: size * 0.54),
    );
  }
}

class _DuoIconPainter extends CustomPainter {
  final DuoIcons icon;
  final Color background;

  _DuoIconPainter(this.icon, this.background);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);

    final line = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final accent = Paint()..color = AppColors.brandYellow;
    final knock = Paint()..color = background;
    final dot = Paint()..color = AppColors.primary;

    RRect rr(double l, double t, double w, double h, double r) =>
        RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));

    void both(Path p, Paint fill) {
      canvas.drawPath(p, fill);
      canvas.drawPath(p, line);
    }

    void seg(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), line);

    Path person(double cx, double top, double bottom, double halfWidth) =>
        Path()
          ..moveTo(cx - halfWidth, bottom)
          ..cubicTo(cx - halfWidth, top + 2, cx - halfWidth * 0.55, top, cx, top)
          ..cubicTo(cx + halfWidth * 0.55, top, cx + halfWidth, top + 2,
              cx + halfWidth, bottom)
          ..close();

    switch (icon) {
      case DuoIcons.scan:
        canvas.drawRRect(rr(4.5, 10.3, 15, 3.4, 1.7), accent);
        // Corner brackets: start → before corner → (curve via corner) → end
        for (final c in [
          [3.0, 8.0, 3.0, 5.0, 3.0, 3.0, 5.0, 3.0, 8.0, 3.0],
          [16.0, 3.0, 19.0, 3.0, 21.0, 3.0, 21.0, 5.0, 21.0, 8.0],
          [21.0, 16.0, 21.0, 19.0, 21.0, 21.0, 19.0, 21.0, 16.0, 21.0],
          [8.0, 21.0, 5.0, 21.0, 3.0, 21.0, 3.0, 19.0, 3.0, 16.0],
        ]) {
          canvas.drawPath(
            Path()
              ..moveTo(c[0], c[1])
              ..lineTo(c[2], c[3])
              ..quadraticBezierTo(c[4], c[5], c[6], c[7])
              ..lineTo(c[8], c[9]),
            line,
          );
        }
        seg(8, 8, 8, 16);
        seg(11, 8, 11, 16);
        seg(13.5, 8, 13.5, 16);
        seg(16, 8, 16, 16);

      case DuoIcons.users:
        canvas.drawCircle(const Offset(16.3, 8.3), 2.9, accent);
        canvas.drawPath(person(16.8, 13.4, 19.8, 3.9), accent);
        canvas.drawCircle(const Offset(9, 8), 3.3, knock);
        canvas.drawCircle(const Offset(9, 8), 3.3, line);
        both(person(9, 13.6, 20, 5.6), knock);

      case DuoIcons.chart:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 3.5)
            ..lineTo(3.5, 20.5)
            ..lineTo(20.5, 20.5),
          line,
        );
        canvas.drawRRect(rr(7.5, 12.5, 3, 5, 1), line);
        canvas.drawRRect(rr(12, 8.5, 3, 9, 1), line);
        final tall = rr(16.5, 4.5, 3, 13, 1);
        canvas.drawRRect(tall, accent);
        canvas.drawRRect(tall, line);

      case DuoIcons.stockRequest:
        final box = rr(3, 10, 9.5, 10, 2);
        canvas.drawRRect(box, accent);
        canvas.drawRRect(box, line);
        seg(3, 14, 12.5, 14);
        seg(10, 5, 20, 5);
        canvas.drawPath(
          Path()
            ..moveTo(17.3, 2.5)
            ..lineTo(20, 5)
            ..lineTo(17.3, 7.5),
          line,
        );
        seg(21, 14.5, 15.5, 14.5);
        canvas.drawPath(
          Path()
            ..moveTo(18.2, 12)
            ..lineTo(15.5, 14.5)
            ..lineTo(18.2, 17),
          line,
        );

      case DuoIcons.grid:
        canvas.drawRRect(rr(3.5, 3.5, 7, 7, 2), line);
        canvas.drawRRect(rr(13.5, 3.5, 7, 7, 2), line);
        canvas.drawRRect(rr(3.5, 13.5, 7, 7, 2), line);
        final cell = rr(13.5, 13.5, 7, 7, 2);
        canvas.drawRRect(cell, accent);
        canvas.drawRRect(cell, line);

      case DuoIcons.history:
        final face = Rect.fromCircle(center: const Offset(12, 12), radius: 8.5);
        canvas.drawArc(face, -math.pi / 2, math.pi / 2, true, accent);
        canvas.drawOval(face, line);
        canvas.drawPath(
          Path()
            ..moveTo(12, 7.5)
            ..lineTo(12, 12)
            ..lineTo(15, 14),
          line,
        );

      case DuoIcons.wallet:
        canvas.drawRRect(rr(3, 5.5, 18, 14, 3), line);
        seg(3, 9, 16, 9);
        final flap = rr(13, 11, 8, 5.5, 2);
        canvas.drawRRect(flap, accent);
        canvas.drawRRect(flap, line);
        canvas.drawCircle(const Offset(16.2, 13.75), 1.1, dot);

      case DuoIcons.package:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(20, 7.5)
            ..lineTo(12, 12)
            ..lineTo(4, 7.5)
            ..close(),
          accent,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(20, 7.5)
            ..lineTo(20, 16.5)
            ..lineTo(12, 21)
            ..lineTo(4, 16.5)
            ..lineTo(4, 7.5)
            ..close()
            ..moveTo(4, 7.5)
            ..lineTo(12, 12)
            ..lineTo(20, 7.5)
            ..moveTo(12, 12)
            ..lineTo(12, 21),
          line,
        );

      case DuoIcons.category:
        final tab = rr(3, 3.5, 10, 8, 2);
        canvas.drawRRect(tab, accent);
        canvas.drawRRect(tab, line);
        final body = rr(3, 8.5, 18, 12, 2.5);
        canvas.drawRRect(body, knock);
        canvas.drawRRect(body, line);

      case DuoIcons.lowStock:
        both(
          Path()
            ..moveTo(12, 3.5)
            ..lineTo(21, 19.5)
            ..lineTo(3, 19.5)
            ..close(),
          accent,
        );
        seg(12, 9.5, 12, 13.5);
        canvas.drawCircle(const Offset(12, 16.5), 1.15, dot);

      case DuoIcons.opname:
        canvas.drawRRect(rr(5, 4.5, 14, 16.5, 2.5), line);
        final clip = rr(8.5, 2.8, 7, 4, 1.5);
        canvas.drawRRect(clip, accent);
        canvas.drawRRect(clip, line);
        canvas.drawPath(
          Path()
            ..moveTo(9, 13.5)
            ..lineTo(11.2, 15.7)
            ..lineTo(15.5, 11.2),
          line,
        );

      case DuoIcons.supplier:
        final cargo = rr(2.5, 5.5, 11, 10.5, 1.5);
        canvas.drawRRect(cargo, accent);
        canvas.drawRRect(cargo, line);
        canvas.drawPath(
          Path()
            ..moveTo(13.5, 9)
            ..lineTo(17.5, 9)
            ..lineTo(21, 12.5)
            ..lineTo(21, 16)
            ..lineTo(13.5, 16),
          line,
        );
        for (final x in [7.0, 17.0]) {
          canvas.drawCircle(Offset(x, 17.5), 2, knock);
          canvas.drawCircle(Offset(x, 17.5), 2, line);
        }

      case DuoIcons.purchase:
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 9)
            ..lineTo(8.5, 7)
            ..cubicTo(8.5, 4.8, 10.1, 3.5, 12, 3.5)
            ..cubicTo(13.9, 3.5, 15.5, 4.8, 15.5, 7)
            ..lineTo(15.5, 9),
          line,
        );
        canvas.drawRRect(rr(4, 8, 16, 13, 2.5), line);
        canvas.drawCircle(const Offset(12, 14.5), 3.3, accent);
        seg(12, 12.8, 12, 16.2);
        seg(10.3, 14.5, 13.7, 14.5);

      case DuoIcons.import:
        canvas.drawPath(
          Path()
            ..moveTo(14, 3)
            ..lineTo(7, 3)
            ..quadraticBezierTo(5, 3, 5, 5)
            ..lineTo(5, 19)
            ..quadraticBezierTo(5, 21, 7, 21)
            ..lineTo(17, 21)
            ..quadraticBezierTo(19, 21, 19, 19)
            ..lineTo(19, 8)
            ..close()
            ..moveTo(14, 3)
            ..lineTo(14, 8)
            ..lineTo(19, 8),
          line,
        );
        final table = rr(8.5, 11, 7, 6.5, 1);
        canvas.drawRRect(table, accent);
        canvas.drawRRect(table, line);
        seg(8.5, 14.25, 15.5, 14.25);
        seg(12, 11, 12, 17.5);

      case DuoIcons.userAdmin:
        canvas.drawCircle(const Offset(10, 8), 3.5, line);
        canvas.drawPath(person(10, 13.8, 20, 6.2), line);
        both(
          Path()
            ..moveTo(17.5, 11)
            ..lineTo(21, 12.3)
            ..lineTo(21, 15.5)
            ..cubicTo(21, 18, 19.3, 19.8, 17.5, 20.5)
            ..cubicTo(15.7, 19.8, 14, 18, 14, 15.5)
            ..lineTo(14, 12.3)
            ..close(),
          accent,
        );

      case DuoIcons.user:
        canvas.drawCircle(const Offset(12, 8), 4, accent);
        canvas.drawCircle(const Offset(12, 8), 4, line);
        canvas.drawPath(
          Path()
            ..moveTo(4.5, 20.5)
            ..cubicTo(4.5, 16.5, 7.8, 14, 12, 14)
            ..cubicTo(16.2, 14, 19.5, 16.5, 19.5, 20.5),
          line,
        );

      case DuoIcons.settings:
        final teeth = Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          canvas.drawLine(
            Offset(12 + 7.4 * math.cos(a), 12 + 7.4 * math.sin(a)),
            Offset(12 + 9 * math.cos(a), 12 + 9 * math.sin(a)),
            teeth,
          );
        }
        canvas.drawCircle(const Offset(12, 12), 6.4, knock);
        canvas.drawCircle(const Offset(12, 12), 6.4, line);
        canvas.drawCircle(const Offset(12, 12), 2.8, accent);
        canvas.drawCircle(const Offset(12, 12), 2.8, line);
    }
  }

  @override
  bool shouldRepaint(_DuoIconPainter old) =>
      old.icon != icon || old.background != background;
}
