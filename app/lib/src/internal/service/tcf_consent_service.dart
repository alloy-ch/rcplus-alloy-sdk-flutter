import 'dart:async';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:logging/logging.dart';
import 'consent_state.dart';

class TCFConsentService {

  final _log = Logger('TCFConsentService');

  final StorageClient _storageClient;

  final _stateController = StreamController<TCFConsentState>.broadcast();

  TCFConsentService({required StorageClient storageClient}) : _storageClient = storageClient {
    _log.info('Initializing...');
    _readConsent();
  }

  Stream<TCFConsentState> get stateStream => _stateController.stream;

  void _readConsent() {
    _storageClient
        .getString(AlloyKey.iabTcfPurposeConsents, defaultValue: '')
        .listen((consentString) {
      _log.fine('Received consent string: "$consentString"');
      final TCFConsentState newState;
      if (consentString.isEmpty) {
        newState = TCFConsentState.notInitialized;
      } else if (consentString.startsWith('1')) {
        newState = TCFConsentState.granted;
      } else {
        newState = TCFConsentState.denied;
      }
      _log.info('State changed to $newState');
      _stateController.add(newState);
    });
  }

  void consentDidChange() async {
    _readConsent();
  }

  void dispose() {
    _log.fine('Disposing...');
    _stateController.close();
  }
}
