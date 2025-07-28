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

  static Future<UserIDs> create({
    String? ssoUserID,
    required String? advertisingID,
    required Map<String, String>? externalIDs,
  }) async {
    String? finalAdvertisingID = advertisingID;

    if (advertisingID == null) {
      try {
        finalAdvertisingID = await AdvertisingId.id(true);
      } catch (e) {
        finalAdvertisingID = null;
      }
    }
    return UserIDs(
      ssoUserID: ssoUserID,
      advertisingID: finalAdvertisingID,
      externalIDs: externalIDs,
    );
  }

  factory UserIDs.fromJson(Map<String, dynamic> json) => _$UserIDsFromJson(json);

  Map<String, dynamic> toJson() => _$UserIDsToJson(this);

  Map<String, dynamic> toCombinedMap() {
    final Map<String, dynamic> combined = <String, dynamic>{};
    if (ssoUserID != null) {
      combined['sso_userid'] = ssoUserID;
    }
    if (advertisingID != null) {
      combined['advertiserUserId'] = advertisingID;
    }
    if (externalIDs != null) {
      externalIDs!.forEach((key, value) {
        combined[key] = value;
      });
    }
    return combined;
  }
}
