import 'dart:async';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/preferences_observer.dart';
import 'package:logging/logging.dart';
import 'consent_state.dart';

class TCFConsentService {

  final _log = Logger('TCFConsentService');

  StreamSubscription? _subscription;

  final _stateController = StreamController<TCFConsentState>.broadcast();

  Stream<TCFConsentState> get stateStream => _stateController.stream;

  TCFConsentService()  {
    _log.info('Initializing...');
    _setupObserver();
  }

  void _setupObserver() {
    _log.fine('Subscribing to tcf ...');
    _subscription?.cancel();
    _subscription = PreferencesObserver.observe(AlloyKey.iabTcfTcString.value).listen((value) async {
        final TCFConsentState newState;
        if (value?.isEmpty ?? true) {
          newState = TCFConsentState.notInitialized;
        } else {
          final purposeConsent = await PreferencesObserver.getValue(
              AlloyKey.iabTcfPurposeConsents.value) as String?;
          newState = (purposeConsent?.startsWith("1") ?? false)
              ? TCFConsentState.granted
              : TCFConsentState.denied;
          _log.info('State changed to $newState');
          _stateController.add(newState);
        }
    });
  }

  void dispose() {
    _log.fine('Disposing...');
    _subscription?.cancel();
    _stateController.close();
  }
}
