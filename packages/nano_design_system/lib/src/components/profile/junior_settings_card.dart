import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';
import '../../accessibility/nano_accessible.dart';

/// Compact settings panel on Junior Profile (VIS-04).
class JuniorSettingsCard extends StatelessWidget {
  const JuniorSettingsCard({
    super.key,
    required this.soundEnabled,
    required this.darkModeEnabled,
    required this.languageLabel,
    this.onSoundChanged,
    this.onDarkModeChanged,
    this.onLanguageTap,
  });

  final bool soundEnabled;
  final bool darkModeEnabled;
  final String languageLabel;
  final ValueChanged<bool>? onSoundChanged;
  final ValueChanged<bool>? onDarkModeChanged;
  final VoidCallback? onLanguageTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NanoSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: NanoSpacing.sm),
          _ToggleRow(
            icon: Icons.volume_up_rounded,
            label: 'Sound',
            value: soundEnabled,
            onChanged: onSoundChanged,
          ),
          NanoAccessibleTarget(
            label: 'Language $languageLabel',
            onTap: onLanguageTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.public, color: Color(0xFF9B6DFF), size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Language',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    languageLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFF9B6DFF)),
                ],
              ),
            ),
          ),
          _ToggleRow(
            icon: Icons.dark_mode_outlined,
            label: 'Dark Mode',
            value: darkModeEnabled,
            onChanged: onDarkModeChanged,
            iconColor: Colors.white54,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    this.onChanged,
    this.iconColor = const Color(0xFF9B6DFF),
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF9B6DFF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
