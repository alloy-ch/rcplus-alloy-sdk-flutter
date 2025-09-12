// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_ids.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserIDs _$UserIDsFromJson(Map<String, dynamic> json) => UserIDs(
      ssoUserID: json['sso_userid'] as String?,
      externalIDs: (json['external_ids'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$UserIDsToJson(UserIDs instance) => <String, dynamic>{
      'sso_userid': instance.ssoUserID,
      'external_ids': instance.externalIDs,
    };
