import 'package:nano_domain/nano_domain.dart';

/// The art a reaction should actually use, after checking what exists (MED-01).
///
/// [tier] can be lower than the tier the runtime asked for. That is the whole
/// point: a generated clip is an enhancement, so a missing or unapproved file
/// quietly drops a rung instead of leaving an empty stage.
class CompanionArtChoice {
  const CompanionArtChoice({
    required this.tier,
    this.generated,
    this.fallback = CompanionArtFallback.none,
  });

  final CompanionAssetTier tier;

  /// Non-null only when a published, approved file is being used.
  final GeneratedAsset? generated;

  /// Why the asked-for tier was not used, for the rare case a caller cares.
  final CompanionArtFallback fallback;

  bool get usesGeneratedClip => generated != null;

  bool get didFallBack => fallback != CompanionArtFallback.none;
}

/// Why a reaction is showing something other than what it asked for (MED-02).
///
/// A fallback is ordinary, not an error, so nothing here is surfaced to a
/// learner. It exists so a curator can tell "nobody has generated this yet" from
/// "the learner asked for less motion", which are the same picture on screen and
/// completely different things to do about.
enum CompanionArtFallback {
  /// The tier the runtime asked for is what is being shown.
  none,

  /// Motion was declined, so a clip was never a candidate.
  reducedMotion,

  /// No published asset exists for this slot yet.
  notGenerated,

  /// Something is published for the slot, but it is not a clip.
  wrongKind,
}

/// Published generated assets, keyed by slot and language (MED-01).
///
/// Built from the client read side, which only ever returns ready and approved
/// rows. Nothing here knows about prompts, providers, or cost: that stays in the
/// administration surface where it belongs.
class CompanionAssetCatalog {
  const CompanionAssetCatalog._(this._bySlot);

  factory CompanionAssetCatalog.fromAssets(Iterable<GeneratedAsset> assets) {
    final bySlot = <String, Map<String, GeneratedAsset>>{};
    for (final asset in assets) {
      if (!asset.isPlayable) continue;
      (bySlot[asset.slot] ??= <String, GeneratedAsset>{})[asset.locale] = asset;
    }
    return CompanionAssetCatalog._(bySlot);
  }

  static const empty = CompanionAssetCatalog._({});

  final Map<String, Map<String, GeneratedAsset>> _bySlot;

  /// Whether any clip is available at all, which is what
  /// [CompanionRuntime.clipsAvailable] needs to know before it promises one.
  bool get hasClips => _bySlot.values.any(
        (byLocale) => byLocale.values.any(
          (asset) => asset.kind == GeneratedAssetKind.video,
        ),
      );

  int get length => _bySlot.values.fold(0, (sum, byLocale) => sum + byLocale.length);

  Iterable<GeneratedAsset> get assets =>
      _bySlot.values.expand((byLocale) => byLocale.values);

  /// Whether [key] still identifies a file in this catalog, by checksum or id.
  /// A cache uses this to drop URLs for files a refresh has replaced.
  bool containsFileKey(String key) =>
      assets.any((asset) => asset.checksum == key || asset.id == key);

  /// Exact language first, then English, because a generated clip is usually
  /// reusable across languages and a silent visual always is.
  GeneratedAsset? lookup({
    required String slot,
    NanoAppLocale locale = NanoAppLocale.en,
  }) {
    final byLocale = _bySlot[slot];
    if (byLocale == null) return null;
    return byLocale[locale.name] ?? byLocale[NanoAppLocale.en.name];
  }

  /// Resolve the art for a reaction against what is published.
  ///
  /// Reduced motion never gets a clip, even when one exists, because a clip is
  /// motion the learner asked not to see.
  CompanionArtChoice choose(
    CompanionReaction reaction, {
    NanoAppLocale locale = NanoAppLocale.en,
    bool reducedMotion = false,
  }) {
    if (reducedMotion) {
      return const CompanionArtChoice(
        tier: CompanionAssetTier.staticArt,
        fallback: CompanionArtFallback.reducedMotion,
      );
    }
    if (reaction.tier != CompanionAssetTier.shortClip) {
      return CompanionArtChoice(tier: reaction.tier);
    }
    final asset = lookup(slot: reaction.assetKey, locale: locale);
    if (asset == null || asset.kind != GeneratedAssetKind.video) {
      // The runtime hoped for a clip and there is none; local animation is the
      // next rung down and it always ships with the app.
      return CompanionArtChoice(
        tier: CompanionAssetTier.localAnimation,
        fallback: asset == null
            ? CompanionArtFallback.notGenerated
            : CompanionArtFallback.wrongKind,
      );
    }
    return CompanionArtChoice(
      tier: CompanionAssetTier.shortClip,
      generated: asset,
    );
  }
}
