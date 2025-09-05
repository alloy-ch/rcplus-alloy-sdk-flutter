// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segment_data_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SegmentDataResponse _$SegmentDataResponseFromJson(Map<String, dynamic> json) =>
    SegmentDataResponse(
      segmentIds: (json['segment_ids'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$SegmentDataResponseToJson(
        SegmentDataResponse instance) =>
    <String, dynamic>{
      'segment_ids': instance.segmentIds,
    };
