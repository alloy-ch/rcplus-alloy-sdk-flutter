import 'dart:async';
import 'package:async/async.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/internal/utility/preferences_observer.dart';
import 'package:logging/logging.dart';
import 'consent_state.dart';

class TCFConsentService {

  final _log = Logger('TCFConsentService');

  StreamSubscription? _subscription;

  final _stateController = StreamController<TCFConsentState>.broadcast();

  Stream<TCFConsentState> get stateStream => _stateController.stream;

  static const int _vendorIdToCheck = 1436;

  TCFConsentState? _lastEmittedState;
  bool _hasBeenInitialized = false;

  TCFConsentService()  {
    _log.info('Initializing...');
    _setupObserver();
  }

  void _setupObserver() {
    _log.fine('Subscribing to TCF keys...');
    _subscription?.cancel();

    // Observe all TCF keys; recompute state when any of them change
    final tcStringStream = PreferencesObserver.observe(AlloyKey.iabTcfTcString.value);
    final purposeConsentsStream = PreferencesObserver.observe(AlloyKey.iabTcfPurposeConsents.value);
    final vendorConsentsStream = PreferencesObserver.observe(AlloyKey.iabTcfVendorConsents.value);
    final cmpSdkIdStream = PreferencesObserver.observe(AlloyKey.iabTcfCmpSdkId.value);

    // Merge all streams and listen for any changes
    _subscription = StreamGroup.merge([
      tcStringStream,
      purposeConsentsStream,
      vendorConsentsStream,
      cmpSdkIdStream,
    ]).listen((_) => _recomputeAndEmit());
  }

  Future<void> _recomputeAndEmit() async {
    final tcString = await PreferencesObserver.getValue(AlloyKey.iabTcfTcString.value) as String?;

    if (tcString?.isEmpty ?? true) {
      // If we had a valid TC string before and now it's empty, this means consent was explicitly denied
      if (_hasBeenInitialized) {
        _emitState(TCFConsentState.denied);
      } else {
        _emitState(TCFConsentState.notInitialized);
      }
      return;
    }

    // Mark as initialized since we have a valid TC string
    _hasBeenInitialized = true;

    final bool purposeGranted = await _isPurposeOneGranted();
    final bool vendorGranted = await _hasVendorConsent(_vendorIdToCheck);

    final TCFConsentState newState = (purposeGranted && vendorGranted)
        ? TCFConsentState.granted
        : TCFConsentState.denied;

    _emitState(newState);
  }

  Future<bool> _isPurposeOneGranted() async {
    final String? purposeConsent = await PreferencesObserver.getValue(
        AlloyKey.iabTcfPurposeConsents.value) as String?;
    if (purposeConsent == null || purposeConsent.isEmpty) return false;
    return purposeConsent[0] == '1';
  }

  Future<bool> _hasVendorConsent(int vendorId) async {
    if (vendorId <= 0) return false;
    final String? vendorConsents = await PreferencesObserver.getValue(
        AlloyKey.iabTcfVendorConsents.value) as String?;
    if (vendorConsents == null || vendorConsents.isEmpty) return false;

    final int index = vendorId - 1;
    if (index < 0 || index >= vendorConsents.length) return false;

    return vendorConsents[index] == '1';
  }

  void _emitState(TCFConsentState state) {
    if (_lastEmittedState == state) return;
    _lastEmittedState = state;
    _log.info('State changed to $state');
    _stateController.add(state);
  }

  void dispose() {
    _log.fine('Disposing...');
    _subscription?.cancel();
    _stateController.close();
  }
}
