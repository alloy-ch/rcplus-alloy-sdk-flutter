import 'dart:async';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'tcf_consent_service.dart';
import 'metadata_service.dart';
import 'consent_state.dart';
import 'metadata_state.dart';

class ConsentService {
  final _log = Logger('ConsentService');
  final TCFConsentService _tcfConsentService;
  final MetadataService _metadataService;
  final _stateController = BehaviorSubject<ConsentState>.seeded(ConsentState.notInitialized);
  StreamSubscription? _tcfSubscription;
  StreamSubscription? _combinedSubscription;

  ConsentService({
    required TCFConsentService tcfConsentService,
    required MetadataService metadataService,
  })  : _tcfConsentService = tcfConsentService,
        _metadataService = metadataService {
    _log.info('ConsentService initializing...');
    _listenForConsentChanges();
  }

  Stream<ConsentState> get stateStream => _stateController.stream;

  /// Current consent state for synchronous access
  ConsentState get currentState => _stateController.value;

  void _listenForConsentChanges() {
    _log.fine('Subscribing to TCF and Metadata state streams.');
    _tcfSubscription = _tcfConsentService.stateStream.listen((tcfState) {
      _log.fine('Received TCF state: $tcfState');
      if (tcfState == TCFConsentState.granted) {
        _log.info('TCF consent granted, fetching metadata.');
        _metadataService.fetchMetadata();
      }
    });

    _combinedSubscription = CombineLatestStream.combine2(
      _tcfConsentService.stateStream,
      _metadataService.stateStream.startWith(MetadataState.notInitialized),
      _combineStates,
    ).listen((newState) {
      if (_stateController.value != newState) {
        _log.info('State changed to $newState');
        _stateController.add(newState);
      }
    });
  }

  ConsentState _combineStates(TCFConsentState tcfState, MetadataState metadataState) {
    final combinedState = () {
      if (tcfState == TCFConsentState.denied) {
        return ConsentState.denied;
      }
      if (tcfState == TCFConsentState.granted && metadataState == MetadataState.valid) {
        return ConsentState.ready;
      }
      return ConsentState.notInitialized;
    }();
    _log.fine('Combining states: TCF=$tcfState, Metadata=$metadataState -> $combinedState');
    return combinedState;
  }

  void dispose() {
    _log.fine('Disposing...');
    _tcfSubscription?.cancel();
    _combinedSubscription?.cancel();
    _stateController.close();
  }
}
