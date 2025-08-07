import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alloy_sdk/src/internal/utility/uuid+v5.dart';
import 'package:device_info_plus/device_info_plus.dart';
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

  final _log = Logger('UserIdentificationService');

  final ApiClient _apiClient;

  final StorageClient _storageClient;

  final _stateController = BehaviorSubject<IdentificationState>.seeded(IdentificationState.notInitialized);

  final _uuid = const Uuid();

  UserIdentificationService({
    required ApiClient apiClient,
    required StorageClient storageClient,
  })  : _apiClient = apiClient,
        _storageClient = storageClient;

  Stream<IdentificationState> get stateStream => _stateController.stream;

  Future<void> resolve({required UserIDs userIDs}) async {
    _log.info('Starting resolution for $userIDs');
    if (await _shouldSkipResolution(userIDs)) {
      _log.fine('Skipping resolution, user data is unchanged.');
      _stateController.add(IdentificationState.ready);
      return;
    }

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
      await _storageClient.setBool(AlloyKey.lastApiErrorOccurred, false);

    } on ApiException catch (e) {
      _log.severe('API error during canonical ID resolution: ${e.message}');
      await _storageClient.setBool(AlloyKey.lastApiErrorOccurred, true);
      await _storageClient.setString(AlloyKey.canonicalUserid, domainUserID);
    } finally {
      _log.fine('Storing user IDs and setting state to ready.');
      await _storageClient.setString(AlloyKey.storedUserIdsJson, json.encode(userIDs.toJson()));
      _stateController.add(IdentificationState.ready);
    }
  }

  /// Determines whether user identification resolution should be skipped.
  /// 
  /// This method checks if the current user data is identical to the previously
  /// stored user data, and if the last API call was successful. Resolution is
  /// skipped if:
  /// - No previous user data exists in storage
  /// - The last API call resulted in an error
  /// - The current user data matches the stored user data exactly
  /// 
  /// This optimization prevents unnecessary API calls when the user's identity
  /// hasn't changed since the last resolution attempt.
  /// 
  /// [userIDs] - The current user identification data to compare against stored data.
  /// 
  /// Returns a [Future<bool>] that is `true` if resolution should be skipped,
  /// `false` if resolution should proceed.
  Future<bool> _shouldSkipResolution(UserIDs userIDs) async {
    final lastApiError = await _storageClient.getBool(AlloyKey.lastApiErrorOccurred, defaultValue: false).first;
    if (lastApiError) return false;

    final storedUserIDsJson = await _storageClient.getString(AlloyKey.storedUserIdsJson, defaultValue: '').first;
    if (storedUserIDsJson.isEmpty) return false;

    return storedUserIDsJson == json.encode(userIDs.toJson());
  }

  /// Creates or retrieves a domain user ID for the current device.
  /// 
  /// This method first checks if a domain user ID already exists in storage.
  /// If found, it returns the existing ID. If not, it creates a new one using
  /// the device's identifier (iOS: identifierForVendor, Android: device ID)
  /// or generates a UUID v4 as fallback.
  /// 
  /// The newly created domain user ID is stored along with its creation timestamp.
  /// 
  /// Returns a [Future<String>] containing the domain user ID.
  Future<String> _createDomainUserID() async {
    final storedDomainId = await _storageClient.getString(AlloyKey.domainUserid, defaultValue: '').first;
    if (storedDomainId.isNotEmpty) {
      return storedDomainId;
    }

    _log.fine('No domain user ID found, creating a new one.');
    String? deviceId;
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor;
    } else if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = generateUUIDv5(androidInfo.id);
    }

    String newDomainId = deviceId ?? _uuid.v4();
    newDomainId = newDomainId.toLowerCase();
    _log.fine('New domain user ID created: $newDomainId');
    await _storageClient.setString(AlloyKey.domainUserid, newDomainId);
    await _storageClient.setInt(AlloyKey.domainUseridCreatedAt, DateTime.now().millisecondsSinceEpoch);
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
