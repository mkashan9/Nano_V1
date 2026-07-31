import '../accessibility/accessibility_preferences.dart';
import '../l10n/nano_app_locale.dart';

/// Rules for the learner-chosen companion name.
///
/// Validation is structural only. Word-level safety belongs to the moderation
/// modules; this name is private to the learner and never shown to others.
abstract final class CompanionNamePolicy {
  static const defaultName = 'Nori';
  static const maxLength = 24;

  static final _allowed = RegExp(r"^[\p{L}\p{N} '\-]+$", unicode: true);
  static final _hasLetter = RegExp(r'\p{L}', unicode: true);

  static String normalize(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String? validate(String raw) {
    final name = normalize(raw);
    if (name.isEmpty) return 'Enter a name';
    if (name.length > maxLength) return 'Use $maxLength characters or fewer';
    if (!_allowed.hasMatch(name)) return 'Letters and numbers only';
    if (!_hasLetter.hasMatch(name)) return 'Include at least one letter';
    return null;
  }
}

/// Personal learner settings: companion name, language, and accessibility.
class StudentPreferences {
  const StudentPreferences({
    required this.userId,
    this.companionName = CompanionNamePolicy.defaultName,
    this.locale = NanoAppLocale.en,
    this.accessibility = AccessibilityPreferences.defaults,
  });

  final String userId;
  final String companionName;
  final NanoAppLocale locale;
  final AccessibilityPreferences accessibility;

  StudentPreferences copyWith({
    String? companionName,
    NanoAppLocale? locale,
    AccessibilityPreferences? accessibility,
  }) {
    return StudentPreferences(
      userId: userId,
      companionName: companionName ?? this.companionName,
      locale: locale ?? this.locale,
      accessibility: accessibility ?? this.accessibility,
    );
  }

  factory StudentPreferences.fromRow(Map<String, dynamic> row) {
    final name = (row['companion_name'] as String?)?.trim();
    return StudentPreferences(
      userId: row['user_id'] as String,
      companionName: (name == null || name.isEmpty)
          ? CompanionNamePolicy.defaultName
          : name,
      locale: row['locale'] == 'ur' ? NanoAppLocale.ur : NanoAppLocale.en,
      accessibility: AccessibilityPreferences(
        textScale: (row['text_scale'] as num?)?.toDouble() ?? 1.0,
        soundEnabled: row['sound_enabled'] as bool? ?? true,
        hapticsEnabled: row['haptics_enabled'] as bool? ?? true,
        reducedMotion: row['reduced_motion'] as bool? ?? false,
        captionsEnabled: row['captions_enabled'] as bool? ?? true,
        classroomMode: row['classroom_mode'] as bool? ?? false,
      ),
    );
  }

  Map<String, dynamic> toRow() => {
        'user_id': userId,
        'companion_name': CompanionNamePolicy.normalize(companionName),
        'locale': locale.tag,
        'sound_enabled': accessibility.soundEnabled,
        'haptics_enabled': accessibility.hapticsEnabled,
        'captions_enabled': accessibility.captionsEnabled,
        'reduced_motion': accessibility.reducedMotion,
        'classroom_mode': accessibility.classroomMode,
        'text_scale': double.parse(accessibility.textScale.toStringAsFixed(2)),
      };
}
