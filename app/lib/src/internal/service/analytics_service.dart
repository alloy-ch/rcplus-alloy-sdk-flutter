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
import 'package:alloy_sdk/src/internal/service/segment_service.dart';
import 'package:alloy_sdk/src/models/segment_data_response.dart';

class AnalyticsService {
  final _log = Logger('AnalyticsService');
  late final ApiClient _apiClient;
  late final StorageClient _storageClient;
  late final TCFConsentService _tcfConsentService;
  late final MetadataService _metadataService;
  late final ConsentService _consentService;
  late final UserIdentificationService _userIdentificationService;
  late final TrackingService _trackingService;
  late final ContextualService _contextualService;
  late final SegmentService _segmentService;

  StreamSubscription? _subscription;
  bool _isProcessingConsentDenial = false;

  Future<void> init({required AlloyConfiguration configuration, required StorageClient storageClient}) async {
    _log.info('Initializing...');
    _apiClient = ApiClient(configuration: configuration);
    _storageClient = storageClient;
    _tcfConsentService = TCFConsentService();
    _contextualService = ContextualService(apiClient: _apiClient);
    _metadataService = MetadataService(apiClient: _apiClient, storageClient: storageClient, configuration: configuration);
    _consentService = ConsentService(tcfConsentService: _tcfConsentService, metadataService: _metadataService);
    _userIdentificationService = UserIdentificationService(apiClient: _apiClient, storageClient: storageClient);
    _trackingService = TrackingService(storageClient: storageClient);
    _segmentService = SegmentService(apiClient: _apiClient, consentService: _consentService);

    _log.fine('Setting up combined state stream listener.');
    _subscription = CombineLatestStream.combine2(
      _consentService.stateStream,
      _userIdentificationService.stateStream,
      (ConsentState consentState, IdentificationState idState) => (consentState, idState),
    ).listen((states) async {
      final (consentState, idState) = states;
      _log.fine('State change: Consent -> $consentState, Identification -> $idState');
      
      if (consentState == ConsentState.ready && idState == IdentificationState.ready) {
        _log.info('Consent and Identification are ready. Starting tracking service.');
        await _trackingService.start(configuration: configuration);
        _isProcessingConsentDenial = false; // Reset flag when consent is ready
      } else if (consentState == ConsentState.denied && !_isProcessingConsentDenial) {
        _log.info('Consent denied. Stopping tracking service and clearing data.');
        _isProcessingConsentDenial = true; // Set flag to prevent recursive calls
        await resetState();
      }
    });
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

  Future<SegmentDataResponse> fetchSegmentData({String? visitorId}) async {
    return await _segmentService.fetchSegmentData(visitorId: visitorId);
  }

  /// Access to the current consent state stream
  Stream<ConsentState> get consentStateStream => _consentService.stateStream;

  /// Current consent state for synchronous access
  ConsentState get currentConsentState {
    return _consentService.currentState;
  }

  /// Resets all service states when user consent is withdrawn
  Future<void> resetState() async {
    await _trackingService.stop();
    await _storageClient.clearUserData();
    _userIdentificationService.resetState();
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
