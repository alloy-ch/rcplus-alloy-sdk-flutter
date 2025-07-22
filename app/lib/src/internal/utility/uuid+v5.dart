import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

String generateUUIDv5(String target) {
  final List<int> targetData = utf8.encode(target);

  final List<int> namespaceData = [];

  final List<int> combinedData = namespaceData + targetData;

  final Digest hashedData = sha1.convert(combinedData);

  // For Version 5:
  // Version bits: 0101 (binary for 5) are in the most significant 4 bits of octet 6.
  // Variant bits: 10xx (binary for RFC 4122 variant) are in the most significant 2 bits of octet 8.
  final Uint8List uuidBytes = Uint8List.fromList(hashedData.bytes.sublist(0, 16));

  // Clear the top 4 bits of octet 6 (index 6 in 0-indexed array)
  // Set the version bits (0101 -> 5 << 4 = 0x50)
  uuidBytes[6] = (uuidBytes[6] & 0x0f) | 0x50;

  // Clear the top 2 bits of octet 8 (index 8 in 0-indexed array)
  // Set the variant bits (10xx -> 0x80)
  uuidBytes[8] = (uuidBytes[8] & 0x3f) | 0x80;

  // 8. Convert the 16-byte list into a standard UUID string format.
  return Uuid.unparse(uuidBytes);
}
