import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:advertising_id/advertising_id.dart';
import 'package:alloy_sdk/src/models/alloy_configuration.dart';
import 'package:alloy_sdk/src/models/page_view_parameters.dart';
import 'package:alloy_sdk/src/models/user_ids.dart';
import 'package:alloy_sdk/src/internal/utility/storage_client.dart';
import 'package:alloy_sdk/src/internal/utility/alloy_key.dart';
import 'package:snowplow_tracker/snowplow_tracker.dart';

class TrackingService {

  final _log = Logger('TrackingService');

  SnowplowTracker? _tracker;
  
  bool _isInitialized = false;

  final String _namespace = 'alloyTracker';

  final StorageClient _storageClient;

  TrackingService({
    required StorageClient storageClient,
  }) : _storageClient = storageClient;

  Future<void> start({required AlloyConfiguration configuration}) async {
    if (_isInitialized) {
      _log.info('Already initialized');
      return;
    }
    
    final endpoint = 'events-${configuration.tenant}${configuration.env.domainSuffix}.alloycdn.net';

    String? advertisingId;

    try {
      advertisingId = await AdvertisingId.id(true);
    } catch (e) {
      _log.warning('Error getting advertising ID: $e');
      advertisingId = null;
    }

    final platformContextProperties = PlatformContextProperties(
      androidIdfa: Platform.isAndroid ? advertisingId : null,
      appleIdfa: Platform.isIOS ? advertisingId : null,
    );

    final trackerConfiguration = TrackerConfiguration(
      appId: configuration.appID,
      applicationContext: true,
      base64Encoding: true,
      devicePlatform: DevicePlatform.app,
      lifecycleAutotracking: false,
      platformContext: false,
      platformContextProperties: platformContextProperties,
      screenContext: false,
      screenEngagementAutotracking: false,
      sessionContext: false,
      userAnonymisation: false,
    );

    final subjectConfiguration = SubjectConfiguration(
      userId: await _storageClient.getString(AlloyKey.canonicalUserid, defaultValue: '').first,
      domainUserId: await _storageClient.getString(AlloyKey.domainUserid, defaultValue: '').first,
    );

    _tracker = await Snowplow.createTracker(
      namespace: _namespace,
      endpoint: endpoint,
      method: Method.post,
      trackerConfig: trackerConfiguration,
      subjectConfig: subjectConfiguration,
    );

    _log.info('Initialized');
    _isInitialized = true;
  }

  Future<void> stop() async {
    _log.info('Stopping');
    if (!_isInitialized || _tracker == null) {
      return;
    }
    await trackPageView(parameters: PageViewParameters.empty());
    _tracker = null;
    _isInitialized = false;
  }

  Future<void> trackPageView({
    required PageViewParameters parameters,
  }) async {
    if (!_isInitialized || _tracker == null) {
      _log.info('Ignoring page view event, not initialized or tracker is null');
      return;
    }

    final storedUserIDsJson = await _storageClient.getString(AlloyKey.storedUserIdsJson, defaultValue: '').first;

    final userIDs = UserIDs.fromJson(json.decode(storedUserIDsJson));

    final contexts = <SelfDescribing>[];

    final pageViewData = <String, dynamic>{
      'page_url': parameters.pageURL,
      'page_referer': parameters.referer,
    };
    pageViewData.removeWhere((key, value) => value == null);

    // mobile_pageview_data
    contexts.add(SelfDescribing(
      schema: 'iglu:com.alloy/mobile_pageview_data/jsonschema/1-0-0',
      data: pageViewData,
    ));

    // custom_tracking_attributes
    if (parameters.customTrackingAttributes != null && parameters.customTrackingAttributes!.isNotEmpty) {
      final customTrackingAttributesData = {
        'attributes': jsonEncode(parameters.customTrackingAttributes),
      };
      contexts.add(SelfDescribing(
        schema: 'iglu:com.alloy/custom_tracking_attributes/jsonschema/1-0-0',
        data: customTrackingAttributesData,
      ));
    }

    // extended_attributes
    final tcfv2 = await _storageClient.getString(AlloyKey.iabTcfTcString, defaultValue: '').first;
    final domainUserIdCreatedAt = await _storageClient.getInt(AlloyKey.domainUseridCreatedAt, defaultValue: 0).first;
    final canonicalUserIdCreatedAt = await _storageClient.getInt(AlloyKey.canonicalUseridCreatedAt, defaultValue: 0).first;
    final extendedAttributesData = {
      'sso_userid': userIDs.ssoUserID,
      'content_id': parameters.contentID,
      'logical_path': parameters.logicalPath,
      'tcfv2': tcfv2.isNotEmpty ? tcfv2 : null,
      'domain_userid_created_at': domainUserIdCreatedAt > 0 ? domainUserIdCreatedAt : null,
      'canonical_userid_created_at': canonicalUserIdCreatedAt > 0 ? canonicalUserIdCreatedAt : null,
    };
    if (userIDs.externalIDs != null) {
      extendedAttributesData['user_id_external'] = userIDs.externalIDs!.isNotEmpty ? jsonEncode(userIDs.externalIDs) : null;
    }

    extendedAttributesData.removeWhere((key, value) => value == null);

    contexts.add(SelfDescribing(
      schema: 'iglu:com.alloy/extended_attributes/jsonschema/1-0-0',
      data: extendedAttributesData,
    ));

    _log.info('Tracking page view: ${parameters.pageURL}');
    await _tracker?.track(
      ScreenView(name: "screen_view"),
      contexts: contexts,
    );
    _log.fine('Page view tracking call completed for: ${parameters.pageURL}');
  }
} 