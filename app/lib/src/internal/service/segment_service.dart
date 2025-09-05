import 'dart:async';
import 'package:logging/logging.dart';
import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/models/segment_data_response.dart';
import 'package:alloy_sdk/src/internal/service/consent_service.dart';
import 'package:alloy_sdk/src/internal/service/consent_state.dart';

class SegmentService {

  final _log = Logger('SegmentService');

  final ApiClient _apiClient;
  final ConsentService _consentService;

  SegmentService({required ApiClient apiClient, required ConsentService consentService}) 
    : _apiClient = apiClient, _consentService = consentService;

  Future<SegmentDataResponse> fetchSegmentData({String? visitorId}) async {
    _log.info('Checking consent state before fetching segmented data for visitor');
    
    // Check current consent state first
    final currentConsentState = await _consentService.stateStream.last;
    
    if (currentConsentState != ConsentState.ready) {
      _log.warning('Consent not ready (current state: $currentConsentState). Cannot fetch segmented data.');
      throw StateError('Consent is not ready. Current state: $currentConsentState');
    }
    
    // Validate visitorId after consent check
    if (visitorId == null || visitorId.trim().isEmpty) {
      _log.warning('Invalid visitorId provided: $visitorId');
      throw ArgumentError('visitorId cannot be null or empty');
    }
    
    _log.info('Consent is ready and visitorId is valid. Fetching segmented data for visitor');
    final response = await _apiClient.getSegmentData(visitorId);
    return SegmentDataResponse.fromJson(response);
  }
}