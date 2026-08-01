import 'dart:async';

import 'package:nano_domain/nano_domain.dart';

import 'narration_catalog.dart';

/// The published narration for the current language, fetched rarely and never
/// allowed to fail (MED-03).
///
/// The same three rules as [CompanionAssetCache], for the same reasons: ask once
/// per [ttl], never throw at a caller, and hold signed URLs until shortly before
/// they expire. One rule is new — **the language is part of what is cached**. A
/// learner switching to Urdu must not be handed the English recordings that were
/// already in hand, so a locale change empties the catalog and refetches rather
/// than merging.
class NarrationCache {
  NarrationCache({
    required Future<List<NarrationLine>> Function(NanoAppLocale locale) fetch,
    Future<String> Function(NarrationAudio audio, Duration expiresIn)? sign,
    DateTime Function()? clock,
    this.ttl = const Duration(hours: 6),
    this.signedUrlLifetime = const Duration(minutes: 30),
    this.signedUrlSafetyMargin = const Duration(minutes: 2),
  })  : _fetchLines = fetch,
        _signUrl = sign,
        _clock = clock ?? DateTime.now;

  final Future<List<NarrationLine>> Function(NanoAppLocale locale) _fetchLines;
  final Future<String> Function(NarrationAudio audio, Duration expiresIn)? _signUrl;
  final DateTime Function() _clock;

  final Duration ttl;
  final Duration signedUrlLifetime;
  final Duration signedUrlSafetyMargin;

  NarrationCatalog _catalog = NarrationCatalog.empty;
  NanoAppLocale? _loadedLocale;
  DateTime? _fetchedAt;
  Future<NarrationCatalog>? _inFlight;
  Object? _lastError;
  var fetchCount = 0;

  final _urls = <String, _SignedUrl>{};

  /// What is cached right now, without asking anyone. Safe before any load: an
  /// empty catalog behaves exactly like a library nobody has recorded yet.
  NarrationCatalog get current => _catalog;

  Object? get lastError => _lastError;

  bool get hasAudio => _catalog.hasAudio;

  bool isStaleFor(NanoAppLocale locale) {
    if (_loadedLocale != locale) return true;
    final fetchedAt = _fetchedAt;
    if (fetchedAt == null) return true;
    return _clock().difference(fetchedAt) >= ttl;
  }

  /// The catalog for [locale], fetched if what is held is old or in the wrong
  /// language. Concurrent callers share one fetch.
  Future<NarrationCatalog> load(
    NanoAppLocale locale, {
    bool force = false,
  }) {
    if (!force && !isStaleFor(locale)) return Future.value(_catalog);
    return _inFlight ??=
        _refresh(locale).whenComplete(() => _inFlight = null);
  }

  Future<NarrationCatalog> _refresh(NanoAppLocale locale) async {
    fetchCount++;
    final changedLanguage = _loadedLocale != locale;
    if (changedLanguage) {
      // Nothing from the previous language survives the switch, including URLs.
      _catalog = NarrationCatalog.empty;
      _urls.clear();
    }
    try {
      final lines = await _fetchLines(locale);
      _catalog = NarrationCatalog.fromLines(lines, locale: locale);
      _loadedLocale = locale;
      _fetchedAt = _clock();
      _lastError = null;
      _urls.removeWhere((key, _) => !_catalog.containsFileKey(key));
      return _catalog;
    } catch (error) {
      _lastError = error;
      // Keep the last good answer for this language, or stay empty. Either way
      // the captions on screen are unaffected, because they never came from
      // here. Do not stamp [_fetchedAt] on a failure: a fetch that failed
      // before sign-in must not lock the session into "nothing recorded".
      _loadedLocale = locale;
      return _catalog;
    }
  }

  /// A playable URL, or null when one cannot be produced — which the caller treats
  /// the same as a line nobody has recorded.
  Future<String?> urlFor(NarrationAudio audio) async {
    final sign = _signUrl;
    if (sign == null) return null;

    final cached = _urls[audio.fileKey];
    if (cached != null && cached.expiresAt.isAfter(_clock())) {
      return cached.url;
    }

    try {
      final url = await sign(audio, signedUrlLifetime);
      _urls[audio.fileKey] = _SignedUrl(
        url: url,
        expiresAt: _clock().add(signedUrlLifetime - signedUrlSafetyMargin),
      );
      return url;
    } catch (error) {
      _lastError = error;
      return null;
    }
  }

  int get signedUrlCount => _urls.length;

  /// Forget everything. A shared device must not keep one learner's signed URLs
  /// available to the next person.
  void clear() {
    _catalog = NarrationCatalog.empty;
    _loadedLocale = null;
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
