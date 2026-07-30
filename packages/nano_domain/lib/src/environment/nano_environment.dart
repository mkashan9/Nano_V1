enum NanoEnvironment {
  development,
  staging,
  production;

  static NanoEnvironment fromName(String? value) {
    switch ((value ?? 'development').toLowerCase()) {
      case 'staging':
        return NanoEnvironment.staging;
      case 'production':
      case 'prod':
        return NanoEnvironment.production;
      default:
        return NanoEnvironment.development;
    }
  }

  bool get isProduction => this == NanoEnvironment.production;
  bool get showDebugTools => this != NanoEnvironment.production;
}
