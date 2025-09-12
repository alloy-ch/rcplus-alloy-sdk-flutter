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
    _log.info('Starting segment data fetch for visitorId: ${visitorId ?? "null"}');
    
    // Check current consent state first
    final currentConsentState = await _consentService.stateStream.first;
    _log.info('Current consent state: $currentConsentState');
    
    if (currentConsentState != ConsentState.ready) {
      _log.warning('Segment data fetch blocked - consent not ready (state: $currentConsentState)');
      throw StateError('Consent is not ready. Current state: $currentConsentState');
    }
    
    _log.info('Consent check passed - proceeding with segment data fetch');
    
    // Validate visitorId after consent check
    if (visitorId == null || visitorId.trim().isEmpty) {
      _log.warning('Segment data fetch failed - invalid visitorId: ${visitorId ?? "null"}');
      throw ArgumentError('visitorId cannot be null or empty');
    }
    
    _log.info('Fetching segment data from API for visitorId: $visitorId');
    try {
      final response = await _apiClient.getSegmentData(visitorId);
      _log.info('Segment data API call successful');
      final segmentResponse = SegmentDataResponse.fromJson(response);
      _log.fine('Parsed segment response: ${segmentResponse.segmentIds.length} segments');
      return segmentResponse;
    } catch (e) {
      _log.severe('Segment data API call failed: $e');
      rethrow;
    }
  }
}
