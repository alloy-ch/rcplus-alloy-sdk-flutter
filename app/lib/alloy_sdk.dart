import 'dart:async';

import 'package:alloy_sdk/src/internal/service/analytics_service.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/alloy_log_level.dart';
import 'package:alloy_sdk/src/models/contextual_data_response.dart';
import 'package:alloy_sdk/src/models/page_view_parameters.dart';
import 'package:alloy_sdk/src/models/user_ids.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

export 'package:alloy_sdk/src/models/alloy_configuration.dart';
export 'package:alloy_sdk/src/models/alloy_environment.dart';
export 'package:alloy_sdk/src/models/alloy_log_level.dart';
export 'package:alloy_sdk/src/models/contextual_data_response.dart';
export 'package:alloy_sdk/src/models/page_view_parameters.dart';
export 'package:alloy_sdk/src/models/user_ids.dart';

class AlloySDK {

  static final AlloySDK instance = AlloySDK._internal();

  factory AlloySDK() => instance;

  AlloySDK._internal() {
    _setupLogger();
  }

  final _log = Logger('AlloySDK');

  late final AnalyticsService _analyticsService;

  late final StorageClient _storageClient;

  Future<String?> get visitorID async {
    return await _storageClient.getString(AlloyKey.canonicalUserid, defaultValue: '').first;
  }

  void _setupLogger() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      debugPrint('${record.level.name}: ${record.time}: ${record.loggerName}: ${record.message}');
    });
  }

  Future<void> start({required AlloyConfiguration configuration}) async {
    _setLogLevel(configuration.logLevel);
    _log.info('Starting with configuration: $configuration');
    _storageClient = StorageClient();
    await _storageClient.init();

    _analyticsService = AnalyticsService();
    await _analyticsService.init(configuration: configuration, storageClient: _storageClient);
  }

  void _setLogLevel(AlloyLogLevel level) {
    switch (level) {
      case AlloyLogLevel.none:
        Logger.root.level = Level.OFF;
        break;
      case AlloyLogLevel.error:
        Logger.root.level = Level.SEVERE;
        break;
      case AlloyLogLevel.warning:
        Logger.root.level = Level.WARNING;
        break;
      case AlloyLogLevel.info:
        Logger.root.level = Level.INFO;
        break;
      case AlloyLogLevel.debug:
        Logger.root.level = Level.FINE;
        break;
      case AlloyLogLevel.verbose:
        Logger.root.level = Level.FINER;
        break;
    }
  }

  Future<bool> initialize({required UserIDs userIDs}) async {
    await _analyticsService.resolveUser(userIDs: userIDs);
    return true;
  }

  Future<ContextualDataResponse> fetchContextualData({required String url}) async {
    return _analyticsService.fetchContextualData(url: url);
  }

  Future<void> trackPageView({required PageViewParameters parameters}) async {
    await _analyticsService.trackPageView(parameters: parameters);
  }

  void consentDidChange() {
    _analyticsService.consentDidChange();
  }

  void dispose() {
    _analyticsService.dispose();
  }
}
