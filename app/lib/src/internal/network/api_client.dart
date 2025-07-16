import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_exception.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:logging/logging.dart';
import 'package:alloy_sdk/src/models/user_ids.dart';

/// A client for making API requests to the Alloy backend services.
class ApiClient {

  final _log = Logger('ApiClient');
  
  final http.Client _client;
  
  final AlloyConfiguration _configuration;

  /// Creates an [ApiClient] with the given [AlloyConfiguration].
  ///
  /// Optionally accepts a custom [http.Client] for testing or advanced usage.
  ApiClient({
    required AlloyConfiguration configuration,
    http.Client? client,
  })  : _configuration = configuration,
        _client = client ?? http.Client();

  /// The base URL for the Alloy services endpoint, derived from the configuration.
  String get _baseUrl => 'https://sa-${_configuration.tenant}${_configuration.env.domainSuffix}.alloycdn.net';

  /// Performs a GET request to the given [path] with optional [queryParams].
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  /// Throws an [ApiException] if the response status is not 2xx.
  Future<Map<String, dynamic>> get(String path, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl/$path').replace(queryParameters: queryParams);
    _log.info('Fetching data from $uri');
    final response = await _client.get(uri);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      _log.severe('Failed to load data from $path: ${response.statusCode} ${response.body}');
      throw ApiException('Failed to load data from $path', statusCode: response.statusCode, body: response.body);
    }
  }

  /// Resolves the canonical user ID by calling the `/resolve-canonical-id` endpoint.
  ///
  /// [canonicalID] is the user's canonical identifier.
  /// [userIDs] contains additional user identification data.
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  /// Throws an [ApiException] if the request fails.
  Future<Map<String, dynamic>> resolveCanonicalID(String canonicalID, UserIDs userIDs) async {
    try {
      final path = 'resolve-canonical-id';
      final queryParams = {
        'canonical_id': canonicalID.replaceAll('-', '').toLowerCase(),
      };
      final combinedMap = userIDs.toCombinedMap();
      if (combinedMap.isNotEmpty) {
        queryParams['external_ids'] = jsonEncode(combinedMap);
      }
      return await get(path, queryParams: queryParams);
    } catch (e) {
      throw ApiException('Failed to resolve canonical ID');
    }
  }

  /// Fetches contextual data for the given [url] by calling the `/contextual-data` endpoint.
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  /// Throws an [ApiException] if the request fails.
  Future<Map<String, dynamic>> getContextualData(String url) async {
    final path = 'contextual-data';
    final queryParams = {
      'url': url,
    };
    return await get(path, queryParams: queryParams);
  }

  /// Fetches CMP metadata for the given [cmpId] by calling the `/metadata` endpoint.
  ///
  /// Returns the decoded JSON response as a [Map<String, dynamic>].
  /// Throws an [ApiException] if the request fails.
  Future<Map<String, dynamic>> getMetadata(String cmpId) async {
    final path = 'metadata';
    final queryParams = {
      'app_id': _configuration.appID,
      'environment': 'app',
      'cmp_id': cmpId,
    };
    return await get(path, queryParams: queryParams);
  }
} 