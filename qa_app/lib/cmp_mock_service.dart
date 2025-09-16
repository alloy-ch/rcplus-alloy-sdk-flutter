import 'package:flutter/services.dart';

/// Mock CMP (Consent Management Platform) service for QA testing.
/// 
/// This service mimics the behavior of real CMPs like OneTrust by setting
/// the appropriate IAB TCF (Transparency & Consent Framework) values in
/// native preferences (SharedPreferences on Android, UserDefaults on iOS).
///
/// The SDK's TCFConsentService monitors these values and responds accordingly.
class CMPMockService {
  static const MethodChannel _methodChannel = MethodChannel('qa_app/cmp_mock');

  /// Sets a value in native platform preferences (SharedPreferences/UserDefaults).
  /// This mimics what a real CMP would do when managing consent.
  static Future<void> _setValue(String key, dynamic value) async {
    try {
      await _methodChannel.invokeMethod('setValue', {
        'key': key,
        'value': value,
      });
      print('CMP Mock: Set $key = $value');
    } on PlatformException catch (e) {
      print('CMP Mock: Failed to set $key: ${e.message}');
      throw Exception('Failed to set preference value for key $key: ${e.message}');
    }
  }

  /// Gets a value from native platform preferences.
  static Future<dynamic> _getValue(String key) async {
    try {
      return await _methodChannel.invokeMethod('getValue', {'key': key});
    } on PlatformException catch (e) {
      print('Failed to get value for key $key: ${e.message}');
      return null;
    }
  }

  /// Grants consent by setting IAB TCF values that indicate user has consented.
  /// 
  /// This sets the minimum required values that TCFConsentService checks:
  /// - IABTCF_CmpSdkID: CMP SDK identifier (required for metadata service) - SET FIRST
  /// - IABTCF_TCString: A valid base64-encoded consent string
  /// - IABTCF_PurposeConsents: String where first character is '1' (purpose 1 consented)
  /// - IABTCF_VendorConsents: String where character at position 1435 is '1' (vendor 1436 consented)
  static Future<void> grantConsent() async {
    // Set CMP SDK ID FIRST (required for metadata service) - using a common test CMP ID
    await _setValue('IABTCF_CmpSdkID', 300); // 300 is a common test CMP SDK ID
    
    // Set a minimal valid TCF consent string (base64 encoded)
    await _setValue('IABTCF_TCString', 'CPtVWgAPtVWgAAHABBENCU-AAAAAAAAACiQAAAAAAAA');
    
    // Purpose consents - first character '1' means purpose 1 is consented
    await _setValue('IABTCF_PurposeConsents', '1000000000');
    
    // Vendor consents - need character at position 1435 to be '1' for vendor 1436
    // Create a string with '1' at position 1435 and '0' elsewhere
    final vendorConsents = List.filled(1500, '0');
    vendorConsents[1435] = '1'; // Vendor 1436 (0-indexed position 1435)
    final vendorConsentsString = vendorConsents.join('');
    await _setValue('IABTCF_VendorConsents', vendorConsentsString);
    
    // Debug: verify the vendor consent string has '1' at the right position
    print('CMP Mock: Vendor string length: ${vendorConsentsString.length}, char at 1435: "${vendorConsentsString[1435]}"');
    
    print('CMP Mock: Consent granted - IAB TCF values set including CMP SDK ID');
    
    // Verify values were written by reading them back
    await _verifyValuesWritten();
  }

  /// Verifies that the IAB TCF values were actually written to preferences
  static Future<void> _verifyValuesWritten() async {
    try {
      final cmpId = await _getValue('IABTCF_CmpSdkID');
      final tcfString = await _getValue('IABTCF_TCString');
      final purposeConsents = await _getValue('IABTCF_PurposeConsents');
      print('CMP Mock: Verification - CmpSdkID: $cmpId, TCString: ${tcfString?.toString().substring(0, 20)}..., PurposeConsents: $purposeConsents');
    } catch (e) {
      print('CMP Mock: Failed to verify values: $e');
    }
  }

  /// Denies consent by either removing IAB TCF values or setting them to indicate no consent.
  /// 
  /// This simulates a user rejecting consent in a CMP interface.
  static Future<void> denyConsent() async {
    // Option 1: Remove the TCF string entirely (simulates no consent given)
    await _setValue('IABTCF_TCString', null);
    await _setValue('IABTCF_PurposeConsents', null);
    await _setValue('IABTCF_VendorConsents', null);
    await _setValue('IABTCF_CmpSdkID', null);
    
    print('CMP Mock: Consent denied - IAB TCF values cleared');
  }

  /// Resets consent state by clearing all IAB TCF related preferences.
  /// 
  /// This simulates a user who hasn't interacted with the CMP yet.
  static Future<void> resetConsent() async {
    await _setValue('IABTCF_TCString', null);
    await _setValue('IABTCF_PurposeConsents', null);
    await _setValue('IABTCF_VendorConsents', null);
    await _setValue('IABTCF_CmpSdkID', null);
    await _setValue('IABTCF_gdprApplies', null);
    await _setValue('IABTCF_PolicyVersion', null);
    
    print('CMP Mock: Consent reset - all IAB TCF values cleared');
  }

  /// Sets consent state with incomplete data to test edge cases.
  /// 
  /// This simulates scenarios where CMP data might be partially available.
  static Future<void> setIncompleteConsent() async {
    // Set TCF string but missing purpose/vendor consents
    await _setValue('IABTCF_TCString', 'CPtVWgAPtVWgAAHABBENCU-AAAAAAAAACiQAAAAAAAA');
    await _setValue('IABTCF_CmpSdkID', 300);
    await _setValue('IABTCF_PurposeConsents', null);
    await _setValue('IABTCF_VendorConsents', null);
    
    print('CMP Mock: Incomplete consent set - TCF string present but consents missing');
  }

  /// Gets the current IAB TCF values for debugging purposes.
  static Future<Map<String, dynamic>> getCurrentConsentState() async {
    try {
      final tcfString = await _getValue('IABTCF_TCString');
      final purposeConsents = await _getValue('IABTCF_PurposeConsents');
      final vendorConsents = await _getValue('IABTCF_VendorConsents');
      final cmpSdkId = await _getValue('IABTCF_CmpSdkID');
      
      return {
        'IABTCF_TCString': tcfString,
        'IABTCF_PurposeConsents': purposeConsents,
        'IABTCF_VendorConsents': vendorConsents,
        'IABTCF_CmpSdkID': cmpSdkId,
      };
    } catch (e) {
      return {'error': 'Failed to get consent state: $e'};
    }
  }
}
