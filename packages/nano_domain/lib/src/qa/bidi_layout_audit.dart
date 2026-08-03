import '../l10n/nano_app_locale.dart';
import '../l10n/nano_copy.dart';

/// QA-05 Urdu / bidirectional layout smoke checklist (builds on FND-06).

enum BidiLayoutCheckStatus { pass, warn, fail }

class BidiLayoutAuditCheck {
  const BidiLayoutAuditCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final BidiLayoutCheckStatus status;
  final String detail;

  bool get passed => status != BidiLayoutCheckStatus.fail;
}

class BidiLayoutAuditReport {
  const BidiLayoutAuditReport({
    required this.checks,
    required this.generatedAt,
    required this.locale,
  });

  final List<BidiLayoutAuditCheck> checks;
  final DateTime generatedAt;
  final NanoAppLocale locale;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount =>
      checks.where((check) => check.status == BidiLayoutCheckStatus.fail).length;
}

/// Smoke viewports for small-phone Urdu review (aligned with QA-02 width).
abstract final class BidiLayoutBudgets {
  static const smallPhoneWidth = 360.0;
  static const smallPhoneHeight = 640.0;
  static const textScaleSmoke = 1.3;
}

abstract final class BidiLayoutAuditPolicy {
  static BidiLayoutAuditReport evaluate({
    NanoAppLocale locale = NanoAppLocale.ur,
    double width = BidiLayoutBudgets.smallPhoneWidth,
    double textScale = BidiLayoutBudgets.textScaleSmoke,
    bool sampleCopyPresent = true,
    bool overflowDetected = false,
    bool mixedScriptOk = true,
    DateTime? now,
  }) {
    final copy = NanoCopy(locale);
    final checks = <BidiLayoutAuditCheck>[
      _readingDirection(locale),
      _urduCopy(copy, sampleCopyPresent),
      _smallPhone(width),
      _textScale(textScale),
      _overflow(locale, overflowDetected),
      _mixedScript(mixedScriptOk),
      _localePreviewPointer(),
    ];
    return BidiLayoutAuditReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
      locale: locale,
    );
  }

  static BidiLayoutAuditCheck _readingDirection(NanoAppLocale locale) {
    final expectedRtl = locale == NanoAppLocale.ur;
    final ok = locale.isRtl == expectedRtl;
    return BidiLayoutAuditCheck(
      id: 'bidi.direction',
      title: 'Reading direction',
      status: ok ? BidiLayoutCheckStatus.pass : BidiLayoutCheckStatus.fail,
      detail: ok
          ? '${locale.tag} → ${locale.isRtl ? 'RTL' : 'LTR'} as expected.'
          : '${locale.tag} direction mismatch (isRtl=${locale.isRtl}).',
    );
  }

  static BidiLayoutAuditCheck _urduCopy(NanoCopy copy, bool present) {
    if (copy.locale != NanoAppLocale.ur) {
      return const BidiLayoutAuditCheck(
        id: 'bidi.urdu_copy',
        title: 'Core Urdu copy strings',
        status: BidiLayoutCheckStatus.pass,
        detail: 'EN run — Urdu copy smoke not required.',
      );
    }
    final keysOk = present &&
        copy.greeting('Ali').contains('سلام') &&
        copy.subjects == 'مضامین' &&
        copy.sampleSentence.isNotEmpty;
    return BidiLayoutAuditCheck(
      id: 'bidi.urdu_copy',
      title: 'Core Urdu copy strings',
      status: keysOk ? BidiLayoutCheckStatus.pass : BidiLayoutCheckStatus.fail,
      detail: keysOk
          ? 'Greeting, subjects, and sample sentence resolve in Urdu.'
          : 'Missing or English-fallback core Urdu strings.',
    );
  }

  static BidiLayoutAuditCheck _smallPhone(double width) {
    final ok = width >= BidiLayoutBudgets.smallPhoneWidth;
    return BidiLayoutAuditCheck(
      id: 'bidi.small_phone',
      title: 'Small-phone Urdu width',
      status: ok ? BidiLayoutCheckStatus.pass : BidiLayoutCheckStatus.fail,
      detail: ok
          ? 'Viewport width ${width.toStringAsFixed(0)} ≥ '
              '${BidiLayoutBudgets.smallPhoneWidth.toStringAsFixed(0)}.'
          : 'Width $width is below the small-phone floor.',
    );
  }

  static BidiLayoutAuditCheck _textScale(double textScale) {
    final ok = textScale >= BidiLayoutBudgets.textScaleSmoke;
    return BidiLayoutAuditCheck(
      id: 'bidi.text_scale',
      title: 'Urdu + text-scale smoke',
      status: ok ? BidiLayoutCheckStatus.pass : BidiLayoutCheckStatus.warn,
      detail: ok
          ? 'textScale $textScale meets pilot smoke '
              '(${BidiLayoutBudgets.textScaleSmoke}).'
          : 'textScale $textScale is below pilot smoke; prefer '
              '${BidiLayoutBudgets.textScaleSmoke}.',
    );
  }

  static BidiLayoutAuditCheck _overflow(
    NanoAppLocale locale,
    bool overflowDetected,
  ) {
    if (locale != NanoAppLocale.ur) {
      return const BidiLayoutAuditCheck(
        id: 'bidi.overflow',
        title: 'Urdu overflow smoke',
        status: BidiLayoutCheckStatus.pass,
        detail: 'EN run — overflow smoke not required.',
      );
    }
    return BidiLayoutAuditCheck(
      id: 'bidi.overflow',
      title: 'Urdu overflow smoke',
      status: overflowDetected
          ? BidiLayoutCheckStatus.fail
          : BidiLayoutCheckStatus.pass,
      detail: overflowDetected
          ? 'Overflow detected on small-phone Urdu layout.'
          : 'No overflow flagged for small-phone Urdu smoke.',
    );
  }

  static BidiLayoutAuditCheck _mixedScript(bool ok) {
    return BidiLayoutAuditCheck(
      id: 'bidi.mixed_script',
      title: 'Mixed EN/Urdu + numbers',
      status: ok ? BidiLayoutCheckStatus.pass : BidiLayoutCheckStatus.warn,
      detail: ok
          ? 'Numeric / Latin fragments keep stable embedding in RTL.'
          : 'Mixed-script embedding needs owner review on Locale preview.',
    );
  }

  static BidiLayoutAuditCheck _localePreviewPointer() {
    return const BidiLayoutAuditCheck(
      id: 'bidi.locale_preview',
      title: 'Locale preview surface',
      status: BidiLayoutCheckStatus.pass,
      detail: 'Interactive EN/Urdu sample lives on Locale preview (FND-06).',
    );
  }
}
