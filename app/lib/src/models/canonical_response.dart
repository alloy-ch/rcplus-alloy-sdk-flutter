import 'package:json_annotation/json_annotation.dart';

part 'canonical_response.g.dart';

@JsonSerializable()
class CanonicalResponse {
  @JsonKey(name: 'canonical_id')
  final String canonicalID;

  @JsonKey(name: 'canonical_id_created_at')
  final int createdAt;

  CanonicalResponse({required this.canonicalID, required this.createdAt});

  factory CanonicalResponse.fromJson(Map<String, dynamic> json) => _$CanonicalResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CanonicalResponseToJson(this);
}
