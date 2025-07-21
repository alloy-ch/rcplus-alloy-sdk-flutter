import 'dart:async';
import 'package:alloy_sdk/src/models/page_view_parameters.dart';
import 'package:rxdart/rxdart.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/user_ids.dart';
import 'package:logging/logging.dart';
import 'consent_service.dart';
import 'user_identification_service.dart';
import 'tracking_service.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'tcf_consent_service.dart';
import 'metadata_service.dart';
import 'consent_state.dart';
import 'identification_state.dart';
import 'contextual_service.dart';
import 'package:alloy_sdk/src/models/contextual_data_response.dart';

class AnalyticsService {
  final _log = Logger('AnalyticsService');
  late final StorageClient storageClient;
  late final ApiClient _apiClient;
  late final TCFConsentService _tcfConsentService;
  late final MetadataService _metadataService;
  late final ConsentService _consentService;
  late final UserIdentificationService _userIdentificationService;
  late final TrackingService _trackingService;
  late final ContextualService _contextualService;

  StreamSubscription? _subscription;

  Future<void> init({required AlloyConfiguration configuration, required StorageClient storageClient}) async {
    _log.info('Initializing...');
    _apiClient = ApiClient(configuration: configuration);
    _tcfConsentService = TCFConsentService(storageClient: storageClient);
    _contextualService = ContextualService(apiClient: _apiClient);
    _metadataService = MetadataService(apiClient: _apiClient, storageClient: storageClient, configuration: configuration);
    _consentService = ConsentService(tcfConsentService: _tcfConsentService, metadataService: _metadataService);
    _userIdentificationService = UserIdentificationService(apiClient: _apiClient, storageClient: storageClient);
    _trackingService = TrackingService(storageClient: storageClient);

    _log.fine('Setting up combined state stream listener.');
    _subscription = CombineLatestStream.combine2(
      _consentService.stateStream,
      _userIdentificationService.stateStream,
      (ConsentState consentState, IdentificationState idState) => (consentState, idState),
    ).listen((states) {
      final (consentState, idState) = states;
      _log.fine('State change: Consent -> $consentState, Identification -> $idState');
      if (consentState == ConsentState.ready && idState == IdentificationState.ready) {
        _log.info('Consent and Identification are ready. Starting tracking service.');
        _trackingService.start(configuration: configuration);
      } else if (consentState == ConsentState.denied) {
        _log.info('Consent denied. Stopping tracking service.');
        _trackingService.stop();
      }
    });
    _log.info('Initialized.');
  }

  Future<void> resolveUser({required UserIDs userIDs}) async {
    _log.info('Resolving user with IDs: $userIDs');
    await _userIdentificationService.resolve(userIDs: userIDs);
    _log.fine('User resolution process finished for: $userIDs');
  }

  Future<void> trackPageView({required PageViewParameters parameters}) async {
    _log.info('Tracking page view for: ${parameters.pageURL}');
    await _trackingService.trackPageView(
        parameters: parameters
    );
  }

  Future<ContextualDataResponse> fetchContextualData({required String url}) async {
    return await _contextualService.fetchContextualData(url: url);
  }

  void consentDidChange() {
    _tcfConsentService.consentDidChange();
  }

  void dispose() {
    _log.info('Disposing...');
    _subscription?.cancel();
    _tcfConsentService.dispose();
    _metadataService.dispose();
    _consentService.dispose();
    _userIdentificationService.dispose();
  }
}
