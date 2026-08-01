import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';

import 'nano_clip_player.dart';
import 'nano_voice_player.dart';

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
    bool clipsAvailable = false,
    Set<String> clipSlots = const {},
    this.inactivityGap = const Duration(minutes: 30),
  })  : _clock = clock ?? DateTime.now,
        _runtime = CompanionRuntime.forExperience(
          junior: junior,
          surface: surface,
          preferences: preferences,
          companionName: companionName,
          clipsAvailable: clipsAvailable || clipSlots.isNotEmpty,
          clipSlots: clipSlots,
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
    _silence();
    _runtime = _runtime.withSurface(surface);
    _publish();
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
    // A new line replaces the old one on screen, so the old one must stop being
    // audible under it.
    _silence();
    _runtime = next;
    _publish();
  }

  void dismiss() {
    if (_runtime.reaction == null) return;
    _silence();
    _runtime = _runtime.dismiss();
    _publish();
  }

  var _disposed = false;

  /// Announce a change, and re-resolve the picture while we are here.
  ///
  /// Art resolution is asynchronous — a signed URL has to be minted — so this
  /// notifies immediately with what is already known and notifies again if a
  /// URL lands. A caller therefore never waits on the network to see a
  /// reaction; it sees the placeholder first and the picture a moment later.
  void _publish() {
    _syncArt();
    if (_disposed) return;
    notifyListeners();
  }

  /// Whichever player just started, stopped, or reached the end. The stage
  /// shows a clip while it plays and the still after it ends, so it has to be
  /// told when playback finishes on its own.
  void _onPlayerChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _player?.removeListener(_onPlayerChanged);
    _clipPlayer?.removeListener(_onPlayerChanged);
    super.dispose();
  }

  /// Stop any narration or clip, without waiting for either. Called whenever
  /// the words or the art on screen change.
  void _silence() {
    final player = _player;
    if (player != null && player.isPlaying) player.stop();
    final clipPlayer = _clipPlayer;
    if (clipPlayer != null && clipPlayer.isPlaying) clipPlayer.stop();
  }

  /// Whether any generated clip has been published (MED-02).
  ///
  /// The answer arrives from the network, after screens are already up, so it is
  /// applied without disturbing them: a reaction on screen stays, cooldowns and
  /// the session budget carry on, and only later reactions can reach for a clip.
  /// False is the normal state and the app is complete in it.
  void setClipsAvailable(bool available) {
    final next = _runtime.withClipsAvailable(available);
    if (next == _runtime) return;
    _runtime = next;
    _publish();
  }

  /// Learns which reaction slots have a clip (MED-04).
  ///
  /// Same quiet arrival as [setClipsAvailable]: a reaction already on screen
  /// stays, and only later reactions can reach for a clip of their own slot.
  void setClipSlots(Set<String> slots) {
    final next = _runtime.withClipSlots(slots);
    if (next == _runtime) return;
    _runtime = next;
    _publish();
  }

  bool get clipsAvailable => _runtime.clipsAvailable;

  Set<String> get clipSlots => _runtime.clipSlots;

  NarrationCatalog _narration = NarrationCatalog.empty;
  NanoVoicePlayer? _player;
  Future<String?> Function(NarrationAudio audio)? _resolveUrl;

  /// Give the companion a voice (MED-03).
  ///
  /// Every argument is optional and the app is complete without any of them: no
  /// catalog means no line is recorded, no player means nothing can be played, and
  /// in both cases the caption is what a learner gets. Like [setClipsAvailable],
  /// this arrives after screens are up and disturbs nothing — no reaction changes,
  /// no cooldown moves, and the session budget is untouched.
  void attachNarration({
    NarrationCatalog? catalog,
    NanoVoicePlayer? player,
    Future<String?> Function(NarrationAudio audio)? resolveUrl,
  }) {
    final nextCatalog = catalog ?? _narration;
    final changed = nextCatalog != _narration ||
        (player != null && player != _player) ||
        (resolveUrl != null && resolveUrl != _resolveUrl);
    _narration = nextCatalog;
    if (_player == null && player != null) {
      _player = player..addListener(_onPlayerChanged);
    }
    _resolveUrl ??= resolveUrl;
    if (changed) _publish();
  }

  /// What to show and whether it can be heard, for the reaction on screen.
  ///
  /// Null only when there is nothing on screen to say.
  NarrationChoice? get narration {
    final current = _runtime.reaction;
    if (current == null) return null;
    // The reaction already carries the name and whether sound is allowed.
    return _narration.choose(current);
  }

  /// Whether a listen control should appear at all. False is the ordinary state.
  bool get canSpeak =>
      _player != null && _resolveUrl != null && (narration?.canSpeak ?? false);

  /// Play the line on screen, if it can be played.
  ///
  /// Nothing speaks unasked in this module. A learner taps to listen, which keeps
  /// one voice on one device without needing the audio focus rules MED-01 owns,
  /// and means a recording can never surprise a classroom.
  Future<void> speak() async {
    final audio = narration?.audio;
    final player = _player;
    final resolve = _resolveUrl;
    if (audio == null || player == null || resolve == null) return;
    final url = await resolve(audio);
    // A URL that could not be minted is a fallback, not a failure: the caption
    // stays exactly as it was.
    if (url == null) return;
    await player.play(url);
  }

  Future<void> stopSpeaking() => _player?.stop() ?? Future.value();

  CompanionAssetCatalog _artCatalog = CompanionAssetCatalog.empty;
  NanoClipPlayer? _clipPlayer;
  Future<String?> Function(GeneratedAsset asset)? _resolveClipUrl;

  /// Give the companion a clip library (MED-04).
  ///
  /// Every argument is optional and the app is complete without any of them: no
  /// catalog means no clip exists, no player means nothing can be played, and in
  /// both cases the local art is what a learner gets. Like [attachNarration],
  /// this arrives after screens are up and disturbs nothing.
  void attachClips({
    CompanionAssetCatalog? catalog,
    NanoClipPlayer? player,
    Future<String?> Function(GeneratedAsset asset)? resolveUrl,
  }) {
    final nextCatalog = catalog ?? _artCatalog;
    final changed = nextCatalog != _artCatalog ||
        (player != null && player != _clipPlayer) ||
        (resolveUrl != null && resolveUrl != _resolveClipUrl);
    _artCatalog = nextCatalog;
    if (_clipPlayer == null && player != null) {
      _clipPlayer = player..addListener(_onPlayerChanged);
    }
    _resolveClipUrl ??= resolveUrl;
    // Always: the catalog may be unchanged while the resolver that mints its
    // URLs has only just arrived, and that is what turns art into a picture.
    _syncArt();
    if (changed) _publish();
  }

  /// What art this reaction should actually use, after checking what is published.
  ///
  /// Null only when there is nothing on screen to decorate.
  CompanionArtChoice? get art {
    final current = _runtime.reaction;
    if (current == null) return null;
    return _artCatalog.choose(
      current,
      reducedMotion: _runtime.preferences.effectiveReducedMotion,
    );
  }

  /// Whether a play-clip control should appear at all. False is the ordinary
  /// state: no player, no clip for this slot, or reduced motion.
  bool get canShowClip =>
      _clipPlayer != null &&
      _resolveClipUrl != null &&
      (art?.usesGeneratedClip ?? false);

  String? _artUrl;
  String? _artAssetId;

  /// A URL for the approved picture of the reaction on screen, once one has
  /// been minted (MED-08). Null is ordinary and means the design system draws
  /// its placeholder instead — no art is published for this slot, no resolver
  /// is attached, or the URL has not arrived yet.
  String? get artUrl => _artUrl;

  /// The surface for the clip playing now, or null. Passed through rather than
  /// interpreted: the controller does not know what decodes it.
  Widget? get clipView => _clipPlayer?.view;

  bool get isPlayingClip => _clipPlayer?.isPlaying ?? false;

  bool get isSpeaking => _player?.isPlaying ?? false;

  /// Mint a URL for the picture this reaction should show.
  ///
  /// Two things keep this cheap: an asset already resolved is not resolved
  /// again, and the resolver behind it caches signed URLs by checksum. A
  /// reaction that moves on before the URL lands discards it, so a slow mint
  /// can never paint the previous picture over the current one.
  void _syncArt() {
    final asset = art?.still;
    if (asset == null) {
      _artUrl = null;
      _artAssetId = null;
      return;
    }
    if (asset.id == _artAssetId) return;
    _artAssetId = asset.id;
    _artUrl = null;
    final resolve = _resolveClipUrl;
    if (resolve == null) return;
    unawaited(
      resolve(asset).then(
        (url) {
          // The reaction moved on while the URL was being minted.
          if (_disposed || url == null || _artAssetId != asset.id) return;
          _artUrl = url;
          notifyListeners();
        },
        // A URL that could not be minted is a fallback, not a failure: the
        // placeholder stays and nothing is thrown at a widget.
        onError: (_) {},
      ),
    );
  }

  /// Play the clip for the reaction on screen, if one can be played.
  ///
  /// Nothing plays unasked in this module. A learner taps to watch, which keeps
  /// a silent clip from surprising a classroom the way autoplay would, and means
  /// reduced motion never has to fight a video that already started.
  Future<void> playClip() async {
    final asset = art?.generated;
    final player = _clipPlayer;
    final resolve = _resolveClipUrl;
    if (asset == null || player == null || resolve == null) return;
    final url = await resolve(asset);
    // A URL that could not be minted is a fallback, not a failure: the local art
    // stays exactly as it was.
    if (url == null) return;
    await player.play(url);
  }

  Future<void> stopClip() => _clipPlayer?.stop() ?? Future.value();

  void updatePreferences(AccessibilityPreferences preferences) {
    if (_runtime.preferences == preferences) return;
    _runtime = _runtime.withPreferences(preferences);
    _publish();
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
    _publish();
  }

  /// A new session: the appearance budget and the cooldowns start over.
  void endSession() {
    _runtime = _runtime.newSession();
    _lastActivityAt = null;
    _publish();
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
