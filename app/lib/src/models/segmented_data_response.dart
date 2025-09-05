import 'package:json_annotation/json_annotation.dart';

part 'segmented_data_response.g.dart';

@JsonSerializable()
class SegmentedDataResponse {

  @JsonKey(name: 'segmented_ids')
  final List<String> segmentedIds;

  SegmentedDataResponse({required this.segmentedIds});

  factory SegmentedDataResponse.fromJson(Map<String, dynamic> json) => _$SegmentedDataResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SegmentedDataResponseToJson(this);
}