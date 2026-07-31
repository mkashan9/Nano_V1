/// Supported product locales for R0 readiness (full ARB pipeline can follow).
enum NanoAppLocale {
  en,
  ur;

  String get languageCode => name;

  /// BCP-47 tag used by Flutter [Locale].
  String get tag => languageCode;

  bool get isRtl => this == NanoAppLocale.ur;

  static NanoAppLocale fromTag(String? tag) {
    final normalized = (tag ?? 'en').toLowerCase();
    if (normalized.startsWith('ur')) return NanoAppLocale.ur;
    return NanoAppLocale.en;
  }
}
