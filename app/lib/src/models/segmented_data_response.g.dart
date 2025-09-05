// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segmented_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SegmentedDataResponse _$SegmentedDataResponseFromJson(
        Map<String, dynamic> json) =>
    SegmentedDataResponse(
      segmentedIds: (json['segmented_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SegmentedDataResponseToJson(
        SegmentedDataResponse instance) =>
    <String, dynamic>{
      'segmented_ids': instance.segmentedIds,
    };
