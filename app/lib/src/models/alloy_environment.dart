enum AlloyEnvironment {
  development,
  staging,
  production;

  String get domainSuffix {
    switch (this) {
      case AlloyEnvironment.development:
        return '.d';
      case AlloyEnvironment.staging:
        return '.s';
      case AlloyEnvironment.production:
        return '.';
    }
  }
} 