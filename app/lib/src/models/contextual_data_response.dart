import 'package:json_annotation/json_annotation.dart';

part 'contextual_data_response.g.dart';

@JsonSerializable()
class ContextualDataResponse {

  @JsonKey(name: 'alloy_iab')
  final List<String>? iabs;

  @JsonKey(name: 'alloy_topics')
  final List<String>? topics;

  @JsonKey(name: 'canonical_id')
  final String? canonicalID;

  @JsonKey(name: 'attribution')
  final String? attribution;

  @JsonKey(name: 'is_brandsafe')
  final bool? isBrandsafe;

  ContextualDataResponse({
    this.iabs,
    this.topics,
    this.canonicalID,
    this.attribution,
    this.isBrandsafe,
  });

  Map<String, dynamic> toJson() => _$ContextualDataResponseToJson(this);

  factory ContextualDataResponse.fromJson(Map<String, dynamic> json) => _$ContextualDataResponseFromJson(json);
}
