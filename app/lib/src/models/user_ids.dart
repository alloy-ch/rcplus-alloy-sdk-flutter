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
