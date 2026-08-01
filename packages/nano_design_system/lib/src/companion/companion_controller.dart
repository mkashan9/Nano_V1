import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';

/// Session-scoped owner of the companion runtime (CMP-03).
///
/// One controller lives for the session, so a cooldown or a spent appearance
/// budget survives moving between screens. The runtime itself stays pure — the
/// controller is the only place that reads a clock, and even that is injectable.
class CompanionController extends ChangeNotifier {
  CompanionController({
    required bool junior,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    String companionName = 'Nori',
    CompanionSurface surface = CompanionSurface.home,
    DateTime Function()? clock,
    this.inactivityGap = const Duration(minutes: 30),
  })  : _clock = clock ?? DateTime.now,
        _runtime = CompanionRuntime.forExperience(
          junior: junior,
          surface: surface,
          preferences: preferences,
          companionName: companionName,
        );

  final DateTime Function() _clock;

  /// A gap at least this long counts as coming back, not carrying on.
  final Duration inactivityGap;

  CompanionRuntime _runtime;
  DateTime? _lastActivityAt;

  CompanionRuntime get runtime => _runtime;

  CompanionReaction? get reaction => _runtime.reaction;

  CompanionSurface get surface => _runtime.surface;

  /// True when [surface] is the one currently in front. A single companion
  /// speaks at a time, so a screen left behind a pushed route stops showing it.
  bool isCurrent(CompanionSurface surface) => _runtime.surface == surface;

  /// The learner moved to another screen: the mode changes and any reaction from
  /// the previous screen is cleared, but cooldowns and the budget carry over.
  void enterSurface(CompanionSurface surface) {
    if (_runtime.surface == surface) return;
    _runtime = _runtime.withSurface(surface);
    notifyListeners();
  }

  /// Reports a moment. Suppressed moments are a no-op, so a screen may report
  /// freely without knowing the rules.
  void report(
    CompanionEvent event, {
    CompanionSurface? surface,
    int seed = 0,
  }) {
    final now = _clock();
    _lastActivityAt = now;
    var next = _runtime;
    if (surface != null && surface != next.surface) {
      next = next.withSurface(surface);
    }
    next = next.notify(event, now: now, seed: seed);
    if (next == _runtime) return;
    _runtime = next;
    notifyListeners();
  }

  void dismiss() {
    if (_runtime.reaction == null) return;
    _runtime = _runtime.dismiss();
    notifyListeners();
  }

  void updatePreferences(AccessibilityPreferences preferences) {
    if (_runtime.preferences == preferences) return;
    _runtime = _runtime.withPreferences(preferences);
    notifyListeners();
  }

  /// The app came back to the foreground. A long gap is greeted as a return; a
  /// short one is ignored, because switching apps for ten seconds is not an
  /// absence worth commenting on.
  void appResumed() {
    final now = _clock();
    final last = _lastActivityAt;
    _lastActivityAt = now;
    if (last == null || now.difference(last) < inactivityGap) return;
    final next = _runtime.notify(CompanionEvent.returnFromInactivity, now: now);
    if (next == _runtime) return;
    _runtime = next;
    notifyListeners();
  }

  /// A new session: the appearance budget and the cooldowns start over.
  void endSession() {
    _runtime = _runtime.newSession();
    _lastActivityAt = null;
    notifyListeners();
  }
}

/// Makes the session's [CompanionController] available to every surface.
class NanoCompanionScope extends InheritedNotifier<CompanionController> {
  const NanoCompanionScope({
    super.key,
    required CompanionController controller,
    required super.child,
  }) : super(notifier: controller);

  static CompanionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<NanoCompanionScope>()
        ?.notifier;
  }

  static CompanionController of(BuildContext context) {
    final controller = maybeOf(context);
    assert(controller != null, 'NanoCompanionScope not found');
    return controller!;
  }
}
