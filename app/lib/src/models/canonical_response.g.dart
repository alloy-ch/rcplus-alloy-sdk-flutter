// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canonical_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanonicalResponse _$CanonicalResponseFromJson(Map<String, dynamic> json) =>
    CanonicalResponse(
      canonicalID: json['canonical_id'] as String,
      createdAt: (json['canonical_id_created_at'] as num).toInt(),
    );

Map<String, dynamic> _$CanonicalResponseToJson(CanonicalResponse instance) =>
    <String, dynamic>{
      'canonical_id': instance.canonicalID,
      'canonical_id_created_at': instance.createdAt,
    };
