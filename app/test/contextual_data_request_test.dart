import 'package:alloy_sdk/src/internal/network/api_client.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/alloy_environment.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter_test/flutter_test.dart';

/// Captures the outgoing request and answers it with an empty JSON object,
/// so no network call is made.
class _CapturingInterceptor extends dio.Interceptor {
  dio.RequestOptions? lastRequest;

  @override
  void onRequest(dio.RequestOptions options, dio.RequestInterceptorHandler handler) {
    lastRequest = options;
    handler.resolve(dio.Response(requestOptions: options, statusCode: 200, data: <String, dynamic>{}));
  }
}

void main() {
  late _CapturingInterceptor interceptor;
  late ApiClient apiClient;

  setUp(() {
    interceptor = _CapturingInterceptor();
    apiClient = ApiClient(
      configuration: AlloyConfiguration(tenant: 'test', env: AlloyEnvironment.production, appID: 'app'),
      client: dio.Dio()..interceptors.add(interceptor),
    );
  });

  const url = 'https://www.blick.ch/news/politik/article123';

  test('sends only uri when no content ID is given', () async {
    await apiClient.getContextualData(url);

    expect(interceptor.lastRequest!.queryParameters, {'uri': url});
  });

  test('sends contentId alongside uri when a content ID is given', () async {
    await apiClient.getContextualData(url, contentId: 'article-12345');

    expect(interceptor.lastRequest!.queryParameters, {'uri': url, 'contentId': 'article-12345'});
    expect(interceptor.lastRequest!.uri.query, contains('contentId=article-12345'));
  });

  for (final blank in ['', '   ', '\n\t']) {
    test('omits contentId for blank value ${blank.codeUnits}', () async {
      await apiClient.getContextualData(url, contentId: blank);

      expect(interceptor.lastRequest!.queryParameters, {'uri': url});
    });
  }
}
