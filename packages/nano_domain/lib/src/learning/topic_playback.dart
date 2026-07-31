import '../l10n/nano_app_locale.dart';

/// One caption line with an optional Urdu translation.
class CaptionCue {
  const CaptionCue({
    required this.atSeconds,
    required this.text,
    this.textUr,
  });

  factory CaptionCue.fromRow(Map<String, dynamic> row) {
    return CaptionCue(
      atSeconds: (row['at'] as num?)?.toInt() ?? 0,
      text: (row['text'] as String?) ?? '',
      textUr: row['text_ur'] as String?,
    );
  }

  final int atSeconds;
  final String text;
  final String? textUr;

  String textFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (textUr?.isNotEmpty ?? false)
          ? textUr!
          : text;
}

/// Ordered caption track for one topic version.
class CaptionTrack {
  const CaptionTrack(this.cues);

  factory CaptionTrack.fromRows(Object? value) {
    if (value is! List) return const CaptionTrack([]);
    final cues = [
      for (final row in value)
        if (row is Map) CaptionCue.fromRow(Map<String, dynamic>.from(row)),
    ]..sort((a, b) => a.atSeconds.compareTo(b.atSeconds));
    return CaptionTrack(cues);
  }

  final List<CaptionCue> cues;

  bool get isEmpty => cues.isEmpty;
  bool get isNotEmpty => cues.isNotEmpty;

  /// The cue covering [positionSeconds], or null before the first cue.
  CaptionCue? cueAt(int positionSeconds) {
    CaptionCue? current;
    for (final cue in cues) {
      if (cue.atSeconds <= positionSeconds) {
        current = cue;
      } else {
        break;
      }
    }
    return current;
  }
}

/// Playback rules shared by the player UI and the fake repository.
///
/// These mirror `nano_internal.playback_credit` and `public.complete_topic`.
/// The client uses them to predict what the server will allow; the server
/// remains the only authority that grants credit or completion.
abstract final class PlaybackPolicy {
  /// How often the player reports its position.
  static const heartbeat = Duration(seconds: 15);

  /// Server jitter allowance and per-beat ceiling.
  static const jitterFactor = 1.25;
  static const maxCreditPerBeat = 120;

  /// Watch-time credit the server would grant for one heartbeat.
  static int creditFor({
    required int positionDelta,
    required int elapsedSeconds,
  }) {
    if (positionDelta <= 0 || elapsedSeconds <= 0) return 0;
    final allowedByClock = (elapsedSeconds * jitterFactor).floor();
    final capped = positionDelta < allowedByClock ? positionDelta : allowedByClock;
    return capped < maxCreditPerBeat ? capped : maxCreditPerBeat;
  }

  static int requiredSeconds({
    required int durationSeconds,
    required double threshold,
  }) =>
      (durationSeconds * threshold).ceil();

  static bool canComplete({
    required int watchedSeconds,
    required int durationSeconds,
    required double threshold,
  }) =>
      watchedSeconds >=
      requiredSeconds(durationSeconds: durationSeconds, threshold: threshold);

  static int remainingSeconds({
    required int watchedSeconds,
    required int durationSeconds,
    required double threshold,
  }) {
    final required = requiredSeconds(
      durationSeconds: durationSeconds,
      threshold: threshold,
    );
    final left = required - watchedSeconds;
    return left < 0 ? 0 : left;
  }

  /// Where playback should start. A finished topic replays from the beginning.
  static int resumeFrom({
    required int resumeSeconds,
    required int durationSeconds,
    required bool isCompleted,
  }) {
    if (isCompleted) return 0;
    if (resumeSeconds >= durationSeconds) return 0;
    return resumeSeconds < 0 ? 0 : resumeSeconds;
  }

  static String clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    final minutes = safe ~/ 60;
    final rest = safe % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }
}
