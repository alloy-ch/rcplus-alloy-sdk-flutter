import 'package:json_annotation/json_annotation.dart';

part 'metadata_response.g.dart';

@JsonSerializable()
class MetadataResponse {

  @JsonKey(name: 'cmp_id_valid')
  final bool cmpIsValid;

  MetadataResponse({required this.cmpIsValid});

  Map<String, dynamic> toJson() => _$MetadataResponseToJson(this);

  factory MetadataResponse.fromJson(Map<String, dynamic> json) => _$MetadataResponseFromJson(json);
}
