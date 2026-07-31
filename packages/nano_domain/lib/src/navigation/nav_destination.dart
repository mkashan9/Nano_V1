class NavDestination {
  const NavDestination({
    required this.id,
    required this.label,
    required this.path,
    required this.iconName,
    this.requiredPermission,
    this.requiredFeatureFlag,
    this.requiresFlexEligibility = false,
    this.fallbackPath = '/',
  });

  final String id;
  final String label;
  final String path;
  final String iconName;
  final String? requiredPermission;
  final String? requiredFeatureFlag;
  final bool requiresFlexEligibility;
  final String fallbackPath;
}
