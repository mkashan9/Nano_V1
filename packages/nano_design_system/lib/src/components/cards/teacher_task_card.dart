import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class TeacherTaskCard extends StatelessWidget {
  const TeacherTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(nano.cardRadius),
      ),
      tileColor: NanoColors.adminSurface,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.symmetric(
        horizontal: nano.cardPadding,
        vertical: NanoSpacing.xs,
      ),
    );
  }
}
