import 'dart:async';
import 'package:logging/logging.dart';
import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/models/segmented_data_response.dart';

class SegmentedService {

  final _log = Logger('SegmentedService');

  final ApiClient _apiClient;

  SegmentedService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<SegmentedDataResponse> fetchSegmentedData({required String visitorId}) async {
    _log.info('Fetching segmented data for visitor');
    final response = await _apiClient.getSegmentedData(visitorId);
    return SegmentedDataResponse.fromJson(response);
  }
}