import 'alloy_environment.dart';
import 'alloy_log_level.dart';

class AlloyConfiguration {
  final String tenant;
  final AlloyEnvironment env;
  final String appID;
  final AlloyLogLevel logLevel;

  AlloyConfiguration({
    required this.tenant,
    required this.env,
    required this.appID,
    this.logLevel = AlloyLogLevel.none,
  });
}
