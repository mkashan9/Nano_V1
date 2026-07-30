class FeatureFlag {
  const FeatureFlag({
    required this.key,
    required this.enabled,
    this.description = '',
  });

  final String key;
  final bool enabled;
  final String description;
}
