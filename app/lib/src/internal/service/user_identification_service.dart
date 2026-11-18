import 'dart:async';

import 'package:alloy_sdk/src/internal/utility/uuid+v5.dart';
import 'package:uuid/uuid.dart';
import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/internal/network/api_exception.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:alloy_sdk/src/models/user_ids.dart';
import 'package:alloy_sdk/src/models/canonical_response.dart';
import 'package:logging/logging.dart';
import 'identification_state.dart';
import 'package:rxdart/rxdart.dart';

class UserIdentificationService {

  /// Stored user IDs expire after a year without use, like the web SDK's cookies.
  static const userIdMaxAge = Duration(days: 365);

  final _log = Logger('UserIdentificationService');

  final ApiClient _apiClient;

  final StorageClient _storageClient;

  final _stateController = BehaviorSubject<IdentificationState>.seeded(IdentificationState.notInitialized);

  final _uuid = const Uuid();

  UserIDs? _userIDs;

  /// The user IDs passed to the last resolution, kept in memory only.
  UserIDs? get userIDs => _userIDs;

  UserIdentificationService({
    required ApiClient apiClient,
    required StorageClient storageClient,
  })  : _apiClient = apiClient,
        _storageClient = storageClient;

  Stream<IdentificationState> get stateStream => _stateController.stream;

  /// Reset the identification state to notInitialized (called when consent is denied)
  void resetState() {
    _log.info('Resetting identification state to notInitialized');
    _userIDs = null;
    _stateController.add(IdentificationState.notInitialized);
  }

  /// Removes the domain and canonical user IDs when they have not been used for [userIdMaxAge],
  /// so that new ones are generated on the next resolution.
  /// IDs stored before the expiry existed get the current time as their last use.
  Future<void> expireUserIdsIfUnused({DateTime? now}) async {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    await _storageClient.removeLegacyKeys();
    final lastUsedAt = await _storageClient.getInt(AlloyKey.useridLastUsedAt, defaultValue: 0).first;
    if (lastUsedAt == 0) {
      await _storageClient.setInt(AlloyKey.useridLastUsedAt, nowMs);
    } else if (nowMs - lastUsedAt > userIdMaxAge.inMilliseconds) {
      _log.info('Stored user IDs expired after a year without use');
      await _storageClient.removeUserIds();
    }
  }

  Future<void> resolve({required UserIDs userIDs}) async {
    _log.info('Starting resolution for $userIDs');
    _userIDs = userIDs;
    await _storageClient.setInt(AlloyKey.useridLastUsedAt, DateTime.now().millisecondsSinceEpoch);
    final domainUserID = await _createDomainUserID();
    final canonicalID = _determineCanonicalID(domainUserID, userIDs);
    _log.fine('Determined canonical ID: $canonicalID');

    try {
      _log.fine('Calling /resolve-canonical-id endpoint.');
      final response = await _apiClient.resolveCanonicalID(canonicalID, userIDs);
      final canonicalResponse = CanonicalResponse.fromJson(response);
      final resolvedCanonicalId = canonicalResponse.canonicalID;
      final createdAt = canonicalResponse.createdAt;
      _log.info('Successfully resolved canonical ID: $resolvedCanonicalId');

      await _storageClient.setString(AlloyKey.canonicalUserid, resolvedCanonicalId);
      await _storageClient.setInt(AlloyKey.canonicalUseridCreatedAt, createdAt);
      _stateController.add(IdentificationState.ready);

    } on ApiException catch (e) {
      _log.severe('API error during canonical ID resolution: ${e.message}');
      await _storageClient.setString(AlloyKey.canonicalUserid, domainUserID);
      _stateController.add(IdentificationState.ready);
    }
  }

  /// Creates or retrieves a domain user ID for the current device.
  /// 
  /// This method first checks if a domain user ID already exists in storage.
  /// If found, it returns the existing ID. If not, it creates a random UUID v4.
  /// It is not derived from identifierForVendor on iOS, which would return the
  /// same ID again after the stored one expired or was cleared.
  /// 
  /// The newly created domain user ID is stored along with its creation timestamp.
  /// 
  /// Returns a [Future<String>] containing the domain user ID.
  Future<String> _createDomainUserID() async {
    final storedDomainId = await _storageClient.getString(AlloyKey.domainUserid, defaultValue: '').first;
    // NOTE-ab: logic is introduced because of previous bug where deviceInfo.androidInfo.id returns build id instead of device id
    // so we need to reset domainUserId
    final wasReset = await _storageClient.getBool(AlloyKey.domainUseridWasReset, defaultValue: false).first;
    if (storedDomainId.isNotEmpty && wasReset) {
      return storedDomainId;
    }

    _log.fine('No domain user ID found, creating a new one.');
    final newDomainId = _uuid.v4().toLowerCase();
    _log.fine('New domain user ID created: $newDomainId');
    await _storageClient.setString(AlloyKey.domainUserid, newDomainId);
    await _storageClient.setInt(AlloyKey.domainUseridCreatedAt, DateTime.now().millisecondsSinceEpoch);
    await _storageClient.setBool(AlloyKey.domainUseridWasReset, true);
    return newDomainId;
  }

  String _determineCanonicalID(String domainUserID, UserIDs userIDs) {
    final artemisId = userIDs.externalIDs?['artemis_id'];
    if (artemisId != null) {
      return generateUUIDv5(artemisId).replaceAll('-', '').toLowerCase();
    }
    return domainUserID.replaceAll('-', '').toLowerCase();
  }

  void dispose() {
    _log.fine('Disposing...');
    _stateController.close();
  }
}
