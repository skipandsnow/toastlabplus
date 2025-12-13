import 'package:flutter/material.dart';

/// A widget that paints a "hand-drawn" looking container.
/// Production Refinement: Stable, subtle organic shapes (Squircle-ish), not random wobbles.
class HandDrawnContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final VoidCallback? onTap;

  const HandDrawnContainer({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.borderColor = const Color(0xFF4A4036), // Dark Wood
    this.borderWidth = 1.5,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.borderRadius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(padding: padding, margin: margin, child: child);

    if (onTap != null) {
      content = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: content,
        ),
      );
    }

    return CustomPaint(
      painter: _OrganicBoxPainter(
        color: color,
        borderColor: borderColor,
        width: borderWidth,
        radius: borderRadius,
      ),
      child: content,
    );
  }
}

class _OrganicBoxPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final double width;
  final double radius;

  _OrganicBoxPainter({
    required this.color,
    required this.borderColor,
    required this.width,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintFill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final paintBorder = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Production Quality "Organic" Shape
    // Uses a rounded rect but with very slight, fixed control point offsets to feel "soft"
    // instead of mathematically perfect or randomly jittery.

    // Actually, distinct separation of fill and border looks nice in Ghibli styles (offset print look).
    // Let's do a smooth RRect but with a subtle style.

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // 1. Shadow (Soft, Warm)
    final shadowPaint = Paint()
      ..color = const Color(0xFF8D7B68)
          .withValues(alpha: 0.1) // Light Wood shadow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(rrect.shift(const Offset(0, 4)), shadowPaint);

    // 2. Fill (Base)
    canvas.drawRRect(rrect, paintFill);

    // 3. Texture Overlay (Noise) - Simplified as dots for now
    // In a real app, use an image shader. Here, simple subtle dots.
    // skipped for performance/simplicity in code generation

    // 4. Border (Soft)
    if (width > 0) {
      canvas.drawRRect(rrect, paintBorder);
    }

    // 5. Highlight (Soft white reflection on top-left)
    final highlightPath = Path();
    highlightPath.moveTo(radius + 5, 2);
    highlightPath.quadraticBezierTo(size.width * 0.4, 2, size.width * 0.4, 2);

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A specialized painter for subtle paper/watercolor texture background
class CloudBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Fill with base color (handled by scaffold usually, but let's ensure texturing)
    // We will draw soft, large blobs of watercolor-like tint

    final paint = Paint()
      ..color = const Color(0xFFF0EBE0)
          .withValues(alpha: 0.5) // Slightly darker than cream
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        60,
      ); // Very soft blur

    // Stable background blobs
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.1), 120, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 180, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.9), 150, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HandDrawnButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final double width;

  const HandDrawnButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = const Color(0xFFE5AFA0),
    this.textColor = const Color(0xFF4A4036),
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return HandDrawnContainer(
      color: color,
      onTap: onPressed,
      child: Container(
        width: width,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
