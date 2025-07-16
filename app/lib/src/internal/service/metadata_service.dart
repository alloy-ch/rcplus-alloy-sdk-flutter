import 'dart:async';
import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/internal/network/api_exception.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/metadata_response.dart';
import 'package:logging/logging.dart';
import 'metadata_state.dart';

class MetadataService {

  final _log = Logger('MetadataService');

  final ApiClient _apiClient;

  final StorageClient _storageClient;

  final AlloyConfiguration _configuration;

  final _stateController = StreamController<MetadataState>.broadcast();

  MetadataService({
    required ApiClient apiClient,
    required StorageClient storageClient,
    required AlloyConfiguration configuration,
  })  : _apiClient = apiClient,
        _storageClient = storageClient,
        _configuration = configuration {
    _log.info('MetadataService initializing...');
  }

  Stream<MetadataState> get stateStream => _stateController.stream;

  Future<void> fetchMetadata() async {
    _log.info('Fetching metadata...');
    try {
      final cmpId = await _storageClient.getString(AlloyKey.iabTcfCmpSdkId, defaultValue: '').first;
      if (cmpId.isEmpty) {
        _log.severe('CMP SDK ID is missing. Cannot fetch metadata.');
        _stateController.add(MetadataState.error);
        return;
      }
      _log.fine('Found CMP ID: $cmpId');

      _log.fine('Calling /metadata endpoint with params: $cmpId, ${_configuration.appID}, app');
      final response = await _apiClient.getMetadata(cmpId);
      final metadataResponse = MetadataResponse.fromJson(response);
      _log.info('Received metadata response. Status: ${metadataResponse.cmpIsValid}');

      final state = metadataResponse.cmpIsValid ? MetadataState.valid : MetadataState.invalid;
      _stateController.add(state);
    } on ApiException catch (e) {
      _log.severe('API error while fetching metadata: ${e.toString()}');
      _stateController.add(MetadataState.error);
    }
  }

  void dispose() {
    _log.fine('Disposing MetadataService.');
    _stateController.close();
  }
} 