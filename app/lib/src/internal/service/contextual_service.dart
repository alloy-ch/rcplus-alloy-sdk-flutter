import 'dart:async';

import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/models/contextual_data_response.dart';
import 'package:logging/logging.dart';

class ContextualService {

  final _log = Logger('ContextualService');

  final ApiClient _apiClient;

  ContextualService({required ApiClient apiClient}) : _apiClient = apiClient;

  Future<ContextualDataResponse> fetchContextualData({required String url, String? contentId}) async {
    _log.info('Fetching contextual data for $url, contentId: $contentId');
    final response = await _apiClient.getContextualData(url, contentId: contentId);
    return ContextualDataResponse.fromJson(response);
  }
}
