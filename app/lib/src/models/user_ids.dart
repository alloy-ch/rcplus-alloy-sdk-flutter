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

  @JsonKey(name: 'advertising_id')
  final String? advertisingID;

  UserIDs({
    this.ssoUserID,
    this.advertisingID,
    this.externalIDs,
  });

  static Future<String?> getAdvertisingID() async {
    try {
      final adId = await AdvertisingId.id(true);
      // Convert empty string to null for proper JSON serialization
      return (adId?.isEmpty ?? true) ? null : adId;
    } catch (e) {
      return null;
    }
  }

  static Future<UserIDs> create({
    String? ssoUserID,
    required String? advertisingID,
    required Map<String, String>? externalIDs,
  }) async {
    String? finalAdvertisingID = advertisingID;
    if (finalAdvertisingID?.isEmpty ?? true) {
      finalAdvertisingID = await getAdvertisingID();
    }
    return UserIDs(
      ssoUserID: ssoUserID,
      advertisingID: finalAdvertisingID,
      externalIDs: externalIDs,
    );
  }

  factory UserIDs.fromJson(Map<String, dynamic> json) => _$UserIDsFromJson(json);

  Map<String, dynamic> toJson() => _$UserIDsToJson(this);

  Future<Map<String, dynamic>> toCombinedMap() async {
    // reconstruct UserIDs to ensure advertisingID is populated
    final userIDs = await UserIDs.create(
      ssoUserID: ssoUserID,
      advertisingID: advertisingID,
      externalIDs: externalIDs,
    );
    final Map<String, dynamic> combined = <String, dynamic>{};
    if (userIDs.ssoUserID != null) {
      combined['sso_userid'] = userIDs.ssoUserID;
    }
    if (userIDs.advertisingID != null) {
      if (Platform.isAndroid) {
        combined['aaid'] = userIDs.advertisingID;
      } else if (Platform.isIOS) {
        combined['idfa'] = userIDs.advertisingID;
      }
    }
    if (userIDs.externalIDs != null) {
      userIDs.externalIDs!.forEach((key, value) {
        combined[key] = value;
      });
    }
    return combined;
  }
}
