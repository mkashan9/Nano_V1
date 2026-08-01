import 'dart:async';

import 'package:nano_domain/nano_domain.dart';

import 'companion_asset_catalog.dart';

/// The published catalog, fetched rarely and never allowed to fail (MED-02).
///
/// Three rules, in the order they matter:
///
///   1. **Ask rarely.** Published assets change when a curator approves one, not
///      while a lesson is running, so one fetch per [ttl] is plenty.
///   2. **Never throw.** A catalog is an enhancement over art that already ships
///      with the app. A failed fetch returns the last known answer, or an empty
///      catalog on a first run — and the screen looks the same either way.
///   3. **Only re-sign when needed.** A private file needs a signed URL, so URLs
///      are held until shortly before they expire and keyed by the file's
///      checksum, which means a regenerated file gets a fresh URL rather than a
///      cached one pointing at bytes that changed.
///
/// Nothing here touches a disk. That keeps the package pure Dart and testable,
/// and it is enough: the bytes themselves are cached by the platform's HTTP
/// layer and the CDN, which is where byte caching belongs.
class CompanionAssetCache {
  CompanionAssetCache({
    required Future<List<GeneratedAsset>> Function() fetch,
    Future<String> Function(GeneratedAsset asset, Duration expiresIn)? sign,
    DateTime Function()? clock,
    this.ttl = const Duration(hours: 6),
    this.signedUrlLifetime = const Duration(minutes: 30),
    this.signedUrlSafetyMargin = const Duration(minutes: 2),
  })  : _fetchAssets = fetch,
        _signUrl = sign,
        _clock = clock ?? DateTime.now;

  final Future<List<GeneratedAsset>> Function() _fetchAssets;
  final Future<String> Function(GeneratedAsset asset, Duration expiresIn)?
      _signUrl;
  final DateTime Function() _clock;

  /// How long a fetched catalog is trusted without asking again.
  final Duration ttl;

  final Duration signedUrlLifetime;

  /// Re-sign this long before expiry, so a URL handed to a player is still valid
  /// when the player actually gets round to using it.
  final Duration signedUrlSafetyMargin;

  CompanionAssetCatalog _catalog = CompanionAssetCatalog.empty;
  DateTime? _fetchedAt;
  Future<CompanionAssetCatalog>? _inFlight;
  Object? _lastError;
  var fetchCount = 0;

  final _urls = <String, _SignedUrl>{};

  /// What is cached right now, without asking anyone. Safe before the first load.
  CompanionAssetCatalog get current => _catalog;

  /// True when a load has produced a catalog, successfully or not.
  bool get isLoaded => _fetchedAt != null;

  bool get isStale {
    final fetchedAt = _fetchedAt;
    if (fetchedAt == null) return true;
    return _clock().difference(fetchedAt) >= ttl;
  }

  /// The last fetch failure, kept for diagnostics. Never thrown at a caller.
  Object? get lastError => _lastError;

  /// Whether a clip exists for any slot, which is what the companion runtime
  /// needs to know before it promises one.
  bool get clipsAvailable => _catalog.hasClips;

  /// The catalog, fetched if the cached one is too old.
  ///
  /// Concurrent callers share one fetch: several screens waking up at once is
  /// the normal case, and it should cost one request.
  Future<CompanionAssetCatalog> load({bool force = false}) {
    if (!force && !isStale) return Future.value(_catalog);
    return _inFlight ??= _refresh().whenComplete(() => _inFlight = null);
  }

  Future<CompanionAssetCatalog> _refresh() async {
    fetchCount++;
    try {
      final assets = await _fetchAssets();
      _catalog = CompanionAssetCatalog.fromAssets(assets);
      _fetchedAt = _clock();
      _lastError = null;
      // A new catalog can rename or replace files, so previously signed URLs are
      // no longer trustworthy.
      _urls.removeWhere((key, _) => !_catalog.containsFileKey(key));
      return _catalog;
    } catch (error) {
      _lastError = error;
      // Keep whatever was already known. On a first run that is an empty
      // catalog, which is exactly what a device with no generated assets has.
      _fetchedAt ??= _clock();
      return _catalog;
    }
  }

  /// A playable URL for [asset], or null when one cannot be produced.
  ///
  /// Null is a normal answer: the caller falls back a rung, the same as it would
  /// for an asset nobody has generated.
  Future<String?> urlFor(GeneratedAsset asset) async {
    final sign = _signUrl;
    final key = asset.checksum ?? asset.id;
    if (sign == null || asset.storagePath == null) return null;

    final cached = _urls[key];
    if (cached != null && cached.expiresAt.isAfter(_clock())) {
      return cached.url;
    }

    try {
      final url = await sign(asset, signedUrlLifetime);
      _urls[key] = _SignedUrl(
        url: url,
        expiresAt: _clock().add(signedUrlLifetime - signedUrlSafetyMargin),
      );
      return url;
    } catch (error) {
      _lastError = error;
      return null;
    }
  }

  /// How many URLs are being held. Useful in tests to prove a second read of the
  /// same asset did not sign again.
  int get signedUrlCount => _urls.length;

  /// Forget everything. A sign-out must not leave one learner's signed URLs
  /// behind for the next person on a shared device.
  void clear() {
    _catalog = CompanionAssetCatalog.empty;
    _fetchedAt = null;
    _lastError = null;
    _urls.clear();
  }
}

class _SignedUrl {
  const _SignedUrl({required this.url, required this.expiresAt});

  final String url;
  final DateTime expiresAt;
}
