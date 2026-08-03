import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

enum JuniorJourneyDayState { completed, reward, upcoming }

class JuniorJourneyDay {
  const JuniorJourneyDay({
    required this.label,
    required this.state,
  });

  final String label;
  final JuniorJourneyDayState state;
}

/// Mon–Sun journey track for Junior Profile (VIS-04).
class JuniorWeeklyJourney extends StatelessWidget {
  const JuniorWeeklyJourney({
    super.key,
    required this.days,
  });

  final List<JuniorJourneyDay> days;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Weekly journey',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: CustomPaint(
                painter: _JourneyLinePainter(days: days),
                child: Row(
                  children: [
                    for (final day in days)
                      Expanded(child: Center(child: _DayNode(day: day))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final day in days)
                  Expanded(
                    child: Text(
                      day.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: day.state == JuniorJourneyDayState.upcoming
                            ? Colors.white38
                            : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayNode extends StatelessWidget {
  const _DayNode({required this.day});

  final JuniorJourneyDay day;

  @override
  Widget build(BuildContext context) {
    final upcoming = day.state == JuniorJourneyDayState.upcoming;
    final reward = day.state == JuniorJourneyDayState.reward;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: upcoming ? const Color(0xFF252845) : const Color(0xFF1A3A6A),
        border: Border.all(
          color: upcoming ? const Color(0xFF3A3F5C) : const Color(0xFF9B6DFF),
          width: 2.5,
        ),
      ),
      child: Icon(
        reward
            ? Icons.card_giftcard_rounded
            : Icons.sentiment_satisfied_alt_rounded,
        size: 20,
        color: upcoming
            ? Colors.white24
            : reward
                ? const Color(0xFF9B6DFF)
                : const Color(0xFFFFD54A),
      ),
    );
  }
}

class _JourneyLinePainter extends CustomPainter {
  _JourneyLinePainter({required this.days});

  final List<JuniorJourneyDay> days;

  @override
  void paint(Canvas canvas, Size size) {
    if (days.length < 2) return;
    final y = size.height / 2;
    final step = size.width / days.length;
    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < days.length - 1; i++) {
      final active = days[i].state != JuniorJourneyDayState.upcoming &&
          days[i + 1].state != JuniorJourneyDayState.upcoming;
      paint.color =
          active ? const Color(0xFF9B6DFF) : const Color(0xFF3A3F5C);
      final x1 = step * i + step / 2;
      final x2 = step * (i + 1) + step / 2;
      canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _JourneyLinePainter oldDelegate) =>
      oldDelegate.days != days;
}
