import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:alloy_sdk/src/internal/utility/preferences_observer.dart';
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
  
  bool _isAllowedToTrack = false;

  final String _namespace = 'alloyTracker';

  final StorageClient _storageClient;

  TrackingService({
    required StorageClient storageClient,
  }) : _storageClient = storageClient;

  Future<void> start({required AlloyConfiguration configuration}) async {
    if (_isAllowedToTrack) {
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
    _isAllowedToTrack = true;
  }

  Future<void> stop() async {
    _log.info('Stopping');
    if (!_isAllowedToTrack) {
      return;
    }
    await trackPageView(parameters: PageViewParameters.empty());
    _isAllowedToTrack = false;
  }

  Future<void> trackPageView({
    required PageViewParameters parameters,
  }) async {
    if (!_isAllowedToTrack) {
      _log.info('Ignoring page view event');
      return;
    }

    final storedUserIDsJson = await _storageClient.getString(AlloyKey.storedUserIdsJson, defaultValue: '').first;

    UserIDs? userIDs;

    try {
      if (storedUserIDsJson.isNotEmpty) {
        final decodedJson = json.decode(storedUserIDsJson);
        userIDs = UserIDs.fromJson(decodedJson);
        _log.info('Using stored UserIDs for page view tracking: $storedUserIDsJson');
      } else {
        _log.severe('UserIDs object is empty, returning early ...');
      }
    } on FormatException catch (e) {
      _log.severe('Error parsing JSON: $e');
    } catch (e) {
      _log.severe('An unexpected error occurred during deserialization: $e');
    }

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
    final tcfv2 = await PreferencesObserver.getValue(AlloyKey.iabTcfTcString.value);
    final domainUserIdCreatedAt = await _storageClient.getInt(AlloyKey.domainUseridCreatedAt, defaultValue: 0).first;
    final canonicalUserIdCreatedAt = await _storageClient.getInt(AlloyKey.canonicalUseridCreatedAt, defaultValue: 0).first;
    final Map<String, dynamic> extendedAttributesData = {
      'content_id': parameters.contentID,
      'logical_path': parameters.logicalPath,
      if (tcfv2?.isNotEmpty ?? false) 'tcfv2': tcfv2,
      if (domainUserIdCreatedAt > 0) 'domain_userid_created_at': domainUserIdCreatedAt,
      if (canonicalUserIdCreatedAt > 0) 'canonical_userid_created_at': canonicalUserIdCreatedAt,
    };
    if (userIDs?.ssoUserID != null) {
      extendedAttributesData['sso_userid'] = userIDs!.ssoUserID;
    }
    Map<String, String> externalIds = userIDs?.externalIDs ?? {};
    final adsId = await UserIDs.getAdvertisingID();
    if (adsId != null && adsId.isNotEmpty) {
      if (Platform.isAndroid) {
        externalIds.putIfAbsent("aaid", () => adsId);
      } else if (Platform.isIOS) {
        externalIds.putIfAbsent("idfa", () => adsId);
      }
    }
    try {
      extendedAttributesData['user_id_external'] = jsonEncode(externalIds);
    } catch (e) {
      _log.warning('Error encoding external IDs to JSON: $e');
    }

    contexts.add(SelfDescribing(
      schema: 'iglu:com.alloy/extended_attributes/jsonschema/1-0-0',
      data: extendedAttributesData,
    ));
    _log.info('Extended Attributes Data: $extendedAttributesData');

    _log.info('Tracking page view: ${parameters.pageURL}');
    await _tracker?.track(
      ScreenView(name: "screen_view"),
      contexts: contexts,
    );
    _log.fine('Page view tracking call completed for: ${parameters.pageURL}');
  }
}
