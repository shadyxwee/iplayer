import 'dart:math' as math;
import 'package:flutter/material.dart';

class DashboardTvGraphic extends StatelessWidget {
  final double size;
  const DashboardTvGraphic({Key? key, this.size = 112}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _TvGraphicPainter(),
    );
  }
}

class _TvGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Antenna Lines
    final antennaPaint = Paint()
      ..color = const Color(0xFF8C8FA9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(38, 18), const Offset(52, 35), antennaPaint);
    canvas.drawLine(const Offset(82, 18), const Offset(68, 35), antennaPaint);

    final antennaTipPaint = Paint()
      ..color = const Color(0xFF8C8FA9)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(const Offset(36, 16), 3, antennaTipPaint);
    canvas.drawCircle(const Offset(84, 16), 3, antennaTipPaint);

    // TV Outer Frame Body
    final framePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final frameBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final frameRRect = RRect.fromLTRBR(15, 32, 105, 100, const Radius.circular(16));
    canvas.drawRRect(frameRRect, framePaint);
    canvas.drawRRect(frameRRect, frameBorderPaint);

    // TV CRT Screen Inner
    final screenPaint = Paint()
      ..color = const Color(0xFF7986CB)
      ..style = PaintingStyle.fill;
    final screenRRect = RRect.fromLTRBR(22, 38, 84, 94, const Radius.circular(10));
    canvas.drawRRect(screenRRect, screenPaint);

    // Inner Screen Gloss Highlight
    final glossPath = Path();
    glossPath.moveTo(26, 42);
    glossPath.quadraticBezierTo(52, 42, 76, 50);
    glossPath.quadraticBezierTo(76, 44, 26, 42);
    glossPath.close();

    final glossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(glossPath, glossPaint);

    // Right Controls Panel on TV
    final controlBarPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromLTRBR(91, 44, 98, 47, const Radius.circular(1.5)), controlBarPaint);
    canvas.drawRRect(RRect.fromLTRBR(91, 52, 98, 55, const Radius.circular(1.5)), controlBarPaint);
    canvas.drawCircle(const Offset(94.5, 67), 3.5, controlBarPaint);
    canvas.drawCircle(const Offset(94.5, 79), 3.5, controlBarPaint);

    // Mini TV Stand Feet
    final feetPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(RRect.fromLTRBR(30, 100, 38, 105, const Radius.circular(2)), feetPaint);
    canvas.drawRRect(RRect.fromLTRBR(82, 100, 90, 105, const Radius.circular(2)), feetPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardMoviesGraphic extends StatelessWidget {
  final double size;
  const DashboardMoviesGraphic({Key? key, this.size = 112}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MoviesGraphicPainter(),
    );
  }
}

class _MoviesGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Popcorn Top Kernels Fluffy Cloud
    canvas.drawOval(Rect.fromCenter(center: const Offset(44, 35), width: 18, height: 16), Paint()..color = const Color(0xFFFEF08A));
    canvas.drawOval(Rect.fromCenter(center: const Offset(60, 30), width: 20, height: 18), Paint()..color = const Color(0xFFFEF9C3));
    canvas.drawOval(Rect.fromCenter(center: const Offset(76, 35), width: 18, height: 16), Paint()..color = const Color(0xFFFEF08A));

    canvas.drawCircle(const Offset(51, 27), 8, Paint()..color = const Color(0xFFFDE047));
    canvas.drawCircle(const Offset(68, 26), 7.5, Paint()..color = const Color(0xFFFACC15));
    canvas.drawCircle(const Offset(37, 40), 7, Paint()..color = const Color(0xFFFDE047));
    canvas.drawCircle(const Offset(83, 40), 7, Paint()..color = const Color(0xFFFDE047));

    // Popcorn Bucket Striped Body
    final cupPath = Path();
    cupPath.moveTo(34, 44);
    cupPath.lineTo(86, 44);
    cupPath.lineTo(78, 102);
    cupPath.lineTo(42, 102);
    cupPath.close();

    // Base Cup (White/Slate-50)
    canvas.drawPath(cupPath, Paint()..color = const Color(0xFFF8FAFC));

    // Red Vertical Stripes (Clipped)
    canvas.save();
    canvas.clipPath(cupPath);

    final stripePaint = Paint()..color = const Color(0xFFE53935);
    canvas.drawRect(const Rect.fromLTWH(42, 44, 7, 60), stripePaint);
    canvas.drawRect(const Rect.fromLTWH(56, 44, 8, 60), stripePaint);
    canvas.drawRect(const Rect.fromLTWH(71, 44, 7, 60), stripePaint);

    canvas.restore(); // end clip

    canvas.restore(); // end scale
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DashboardSeriesGraphic extends StatelessWidget {
  final double size;
  const DashboardSeriesGraphic({Key? key, this.size = 112}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _SeriesGraphicPainter(),
    );
  }
}

class _SeriesGraphicPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 120.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Lower Base of Clapperboard
    final baseRRect = RRect.fromLTRBR(25, 55, 95, 101, const Radius.circular(6));
    canvas.drawRRect(baseRRect, Paint()..color = const Color(0xFF64748B));

    // Chalk lines on board
    final linePaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(33, 67), const Offset(62, 67), linePaint);
    canvas.drawLine(const Offset(33, 78), const Offset(52, 78), linePaint);

    // Darker box
    canvas.drawRRect(RRect.fromLTRBR(72, 65, 87, 80, const Radius.circular(3)), Paint()..color = const Color(0xFF475569));

    // Clapper Top Stick (Hinged at -14 degrees around pivot (25, 55))
    canvas.save();
    canvas.translate(25, 55);
    canvas.rotate(-14 * math.pi / 180);
    canvas.translate(-25, -55);

    final topStickRRect = RRect.fromLTRBR(24, 38, 94, 52, const Radius.circular(3));
    canvas.drawRRect(topStickRRect, Paint()..color = const Color(0xFFCBD5E1));

    // Diagonal Orange Chevrons
    final orangePaint = Paint()..color = const Color(0xFFF97316);

    void drawChevron(double x1, double x2, double x3, double x4) {
      final path = Path()
        ..moveTo(x1, 38)
        ..lineTo(x2, 38)
        ..lineTo(x3, 52)
        ..lineTo(x4, 52)
        ..close();
      canvas.drawPath(path, orangePaint);
    }

    drawChevron(32, 40, 34, 26);
    drawChevron(46, 54, 48, 40);
    drawChevron(60, 68, 62, 54);
    drawChevron(74, 82, 76, 68);
    drawChevron(88, 93, 90, 82);

    canvas.restore(); // end rotation transform

    // Hinge Screw
    canvas.drawCircle(const Offset(27, 53), 3.5, Paint()..color = const Color(0xFF334155));

    canvas.restore(); // end scale
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
