// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'contextual_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContextualDataResponse _$ContextualDataResponseFromJson(
        Map<String, dynamic> json) =>
    ContextualDataResponse(
      iabs: (json['alloy_iab'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      topics: (json['alloy_topics'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      canonicalID: json['canonical_id'] as String?,
      attribution: json['attribution'] as String?,
      isBrandsafe: json['is_brandsafe'] as bool?,
    );

Map<String, dynamic> _$ContextualDataResponseToJson(
        ContextualDataResponse instance) =>
    <String, dynamic>{
      'alloy_iab': instance.iabs,
      'alloy_topics': instance.topics,
      'canonical_id': instance.canonicalID,
      'attribution': instance.attribution,
      'is_brandsafe': instance.isBrandsafe,
    };
