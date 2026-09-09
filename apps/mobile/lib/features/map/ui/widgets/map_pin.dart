import 'package:albab_core/albab_core.dart';
import 'package:flutter/material.dart';

/// The rounded-teardrop pin from the mockup (brief §5): a type-colored drop with a white
/// glyph, enlarged when its listing is the selected one (UC-11: "tapping a pin selects it").
class MapPin extends StatelessWidget {
  const MapPin({super.key, required this.propertyType, this.selected = false});

  final PropertyType propertyType;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final size = selected ? 44.0 : 34.0;
    return AnimatedScale(
      scale: selected ? 1.15 : 1.0,
      duration: const Duration(milliseconds: 150),
      child: CustomPaint(
        size: Size(size, size * 1.2),
        painter: _TeardropPainter(color: propertyType.pinColor),
        child: SizedBox(
          width: size,
          height: size * 1.2,
          child: Align(
            alignment: const Alignment(0, -0.35),
            child: Icon(propertyType.icon, color: Colors.white, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  const _TeardropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..addOval(Rect.fromCircle(center: Offset(w / 2, w / 2), radius: w / 2))
      ..moveTo(w * 0.18, w * 0.62)
      ..quadraticBezierTo(w / 2, h, w * 0.82, w * 0.62)
      ..close();
    canvas.drawShadow(path, Colors.black, 2, false);
    canvas.drawPath(path, paint);
    canvas.drawCircle(Offset(w / 2, w / 2), w * 0.16, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter oldDelegate) => oldDelegate.color != color;
}

/// The count bubble for a cluster of overlapping pins (UC-10: "clustered when dense").
class MapClusterMarker extends StatelessWidget {
  const MapClusterMarker({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Text(
        '$count',
        style: AppTypography.label.copyWith(color: Colors.white),
      ),
    );
  }
}
