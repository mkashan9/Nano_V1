import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// One Builder Dashboard metric tile (VIS-05).
class SeniorDashboardStatCard extends StatelessWidget {
  const SeniorDashboardStatCard({
    super.key,
    required this.value,
    required this.label,
    required this.accent,
    required this.icon,
  });

  final String value;
  final String label;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NanoSpacing.sm),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 20),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white60, fontSize: 11),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 14,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.7)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.1,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.85,
        size.width,
        size.height * 0.25,
      );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.color != color;
}
