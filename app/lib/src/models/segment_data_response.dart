import 'package:json_annotation/json_annotation.dart';

part 'segment_data_response.g.dart';

@JsonSerializable()
class SegmentDataResponse {

  @JsonKey(name: 'segment_ids')
  final List<String> segmentIds;

  SegmentDataResponse({required this.segmentIds});

  factory SegmentDataResponse.fromJson(Map<String, dynamic> json) => _$SegmentDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SegmentDataResponseToJson(this);
}