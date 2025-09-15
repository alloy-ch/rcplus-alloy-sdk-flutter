import 'dart:io';

import 'package:advertising_id/advertising_id.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_ids.g.dart';

@JsonSerializable()
class UserIDs {

  @JsonKey(name: 'sso_userid')
  final String? ssoUserID;

  @JsonKey(name: 'external_ids')
  final Map<String, String>? externalIDs;

  /// @deprecated This field is deprecated and no longer used for advertising ID collection.
  /// 
  /// **Privacy Note**: Advertising ID collection is now handled automatically by the SDK
  /// when proper permissions are granted by the host app. The SDK will:
  /// 
  /// - iOS: Collect IDFA only if user grants App Tracking Transparency permission
  /// - Android: Collect AAID automatically (respects user's limit ad tracking setting)
  /// 
  /// Host apps must implement proper permission handling:
  /// - iOS: Include NSUserTrackingUsageDescription and request ATT permission
  /// - Android: Add com.google.android.gms.permission.AD_ID permission if needed
  /// 
  /// Use [AdvertisingId.id()] directly if you need to check advertising ID availability.
  @JsonKey(name: 'advertising_id')
  @Deprecated('Advertising ID is now collected automatically by the SDK when permissions allow. This field is kept for backward compatibility only.')
  final String? advertisingID;

  UserIDs({
    this.ssoUserID,
    this.externalIDs,
    @Deprecated('The advertisingID resolution is handled internally') this.advertisingID,
  });

  static Future<String?> getAdvertisingID() async {
    try {
      final adId = await AdvertisingId.id(true);
      return (adId?.isEmpty ?? true) ? null : adId;
    } catch (e) {
      return null;
    }
  }


  factory UserIDs.fromJson(Map<String, dynamic> json) => _$UserIDsFromJson(json);

  Map<String, dynamic> toJson() => _$UserIDsToJson(this);

  Future<Map<String, dynamic>> toCombinedMap() async {
    final Map<String, dynamic> combined = <String, dynamic>{};
    if (ssoUserID != null) {
      combined['sso_userid'] = ssoUserID;
    }
    final advertisingID = await getAdvertisingID();
    if (advertisingID != null) {
      if (Platform.isAndroid) {
        combined['aaid'] = advertisingID;
      } else if (Platform.isIOS) {
        combined['idfa'] = advertisingID;
      }
    }
    if (externalIDs != null) {
      externalIDs!.forEach((key, value) {
        combined[key] = value;
      });
    }
    return combined;
  }
}
