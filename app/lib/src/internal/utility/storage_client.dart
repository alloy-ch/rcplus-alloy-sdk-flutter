import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:rx_shared_preferences/rx_shared_preferences.dart';
import 'package:rxdart/rxdart.dart';
import 'alloy_key.dart';

class StorageClient {

  late final RxSharedPreferences _prefs;

  Future<void> init() async {
    _prefs = RxSharedPreferences(
      await SharedPreferences.getInstance(),
      kReleaseMode ? null : RxSharedPreferencesDefaultLogger(),
    );
  }

  Stream<String> getString(AlloyKey key, {required String defaultValue}) {
    return _prefs.getStringStream(key.value).map((value) => value ?? defaultValue).share();
  }

  Stream<bool> getBool(AlloyKey key, {required bool defaultValue}) {
    return _prefs.getBoolStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<int> getInt(AlloyKey key, {required int defaultValue}) {
    return _prefs.getIntStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<double> getDouble(AlloyKey key, {required double defaultValue}) {
    return _prefs.getDoubleStream(key.value).map((value) => value ?? defaultValue);
  }

  Stream<List<String>> getStringList(AlloyKey key, {required List<String> defaultValue}) {
    return _prefs.getStringListStream(key.value).map((value) => value ?? defaultValue);
  }

  Future<void> setString(AlloyKey key, String value) => _prefs.setString(key.value, value);
  Future<void> setBool(AlloyKey key, bool value) => _prefs.setBool(key.value, value);
  Future<void> setInt(AlloyKey key, int value) => _prefs.setInt(key.value, value);
  Future<void> setDouble(AlloyKey key, double value) => _prefs.setDouble(key.value, value);
  Future<void> setStringList(AlloyKey key, List<String> value) => _prefs.setStringList(key.value, value);

  Future<void> remove(AlloyKey key) async {
    await _prefs.remove(key.value);
  }

  /// Clear all user-related data from storage when consent is revoked.
  /// 
  /// This method implements the user's right to data deletion as required by privacy regulations.
  /// It removes all stored user identifiers and tracking data while preserving
  /// consent state information which may be required for legal compliance.
  /// 
  /// **Data Deleted**:
  /// - User canonical ID and domain user ID
  /// - Stored user identification JSON
  /// - API error state flags
  /// - User creation timestamps
  /// 
  /// **Data Preserved** (for legal compliance):
  /// - IAB TCF consent strings (IABTCF_TCString, IABTCF_PurposeConsents, IABTCF_VendorConsents)
  /// - CMP SDK ID (required for IAB TCF compliance)
  /// 
  /// These preserved consent records are managed by the host app's CMP and are 
  /// required for legal compliance under GDPR Article 7(1) and similar regulations.
  Future<void> clearUserData() async {
    // Clear user identification data
    await _prefs.remove(AlloyKey.canonicalUserid.value);
    await _prefs.remove(AlloyKey.canonicalUseridCreatedAt.value);
    await _prefs.remove(AlloyKey.storedUserIdsJson.value);
    await _prefs.remove(AlloyKey.domainUserid.value);
    await _prefs.remove(AlloyKey.domainUseridCreatedAt.value);
    await _prefs.remove(AlloyKey.lastApiErrorOccurred.value);
    
    // Note: We preserve IAB TCF consent strings as they may be required
    // for legal compliance and are managed by the host app's CMP:
    // - IABTCF_TCString: Main consent string
    // - IABTCF_PurposeConsents: Purpose-specific consent
    // - IABTCF_VendorConsents: Vendor-specific consent
    // - IABTCF_CmpSdkID: CMP identification
    // 
    // These records document the user's consent decisions and may be required
    // for compliance audits under GDPR, CCPA, and other privacy regulations.
  }
}
