import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:advertising_id/advertising_id.dart';

class TrackingPermissionService {
  static TrackingPermissionService? _instance;
  
  TrackingPermissionService._();
  
  static TrackingPermissionService get instance {
    _instance ??= TrackingPermissionService._();
    return _instance!;
  }

  /// Request tracking permission and return advertising ID if available
  Future<TrackingPermissionResult> requestTrackingPermission() async {
    try {
      // For iOS, request App Tracking Transparency permission
      if (Platform.isIOS) {
        // Check current status first to provide better feedback
        final currentStatus = await AppTrackingTransparency.trackingAuthorizationStatus;
        
        // If already determined, explain why dialog won't appear
        if (currentStatus != TrackingStatus.notDetermined) {
          String explanation = '';
          switch (currentStatus) {
            case TrackingStatus.denied:
              explanation = 'Previously denied. User must enable in Settings > Privacy & Security > Tracking > Allow Apps to Request to Track, then restart app.';
              break;
            case TrackingStatus.restricted:
              explanation = 'Restricted by device policy or parental controls.';
              break;
            case TrackingStatus.authorized:
              explanation = 'Already authorized.';
              break;
            default:
              explanation = 'Status: $currentStatus';
          }
          
          final advertisingId = currentStatus == TrackingStatus.authorized ? await AdvertisingId.id(true) : null;
          
          return TrackingPermissionResult(
            isGranted: currentStatus == TrackingStatus.authorized,
            advertisingId: advertisingId,
            platform: 'iOS',
            idType: 'IDFA',
            errorMessage: currentStatus != TrackingStatus.authorized ? explanation : null,
          );
        }
        
        // Only request if status is notDetermined (will show dialog)
        final status = await AppTrackingTransparency.requestTrackingAuthorization();
        
        if (status == TrackingStatus.authorized) {
          // Get IDFA if permission granted
          final advertisingId = await AdvertisingId.id(true);
          return TrackingPermissionResult(
            isGranted: true,
            advertisingId: advertisingId,
            platform: 'iOS',
            idType: 'IDFA',
          );
        } else {
          String explanation = '';
          switch (status) {
            case TrackingStatus.denied:
              explanation = 'User denied tracking permission in dialog.';
              break;
            case TrackingStatus.restricted:
              explanation = 'Restricted by device policy or parental controls.';
              break;
            default:
              explanation = 'Status: $status';
          }
          
          return TrackingPermissionResult(
            isGranted: false,
            advertisingId: null,
            platform: 'iOS',
            idType: 'IDFA',
            errorMessage: explanation,
          );
        }
      }
      
      // For Android, get AAID (no permission dialog needed)
      if (Platform.isAndroid) {
        final advertisingId = await AdvertisingId.id(true);
        final isLimitAdTrackingEnabled = await AdvertisingId.isLimitAdTrackingEnabled;
        
        // Handle null case - treat null as "limit ad tracking enabled" (more restrictive)
        final isTrackingLimited = isLimitAdTrackingEnabled ?? true;
        
        return TrackingPermissionResult(
          isGranted: !isTrackingLimited,
          advertisingId: advertisingId,
          platform: 'Android',
          idType: 'AAID',
          errorMessage: isTrackingLimited ? 'Limit Ad Tracking is enabled' : null,
        );
      }
      
      return TrackingPermissionResult(
        isGranted: false,
        advertisingId: null,
        platform: 'Unknown',
        idType: 'Unknown',
        errorMessage: 'Unsupported platform',
      );
      
    } catch (e) {
      return TrackingPermissionResult(
        isGranted: false,
        advertisingId: null,
        platform: Platform.isIOS ? 'iOS' : 'Android',
        idType: Platform.isIOS ? 'IDFA' : 'AAID',
        errorMessage: 'Error requesting tracking permission: $e',
      );
    }
  }

  /// Get current tracking authorization status (iOS only)
  Future<TrackingStatus> getTrackingAuthorizationStatus() async {
    if (Platform.isIOS) {
      return await AppTrackingTransparency.trackingAuthorizationStatus;
    }
    // For Android, we consider it always authorized since there's no permission dialog
    return TrackingStatus.authorized;
  }

  /// Check if we can collect advertising ID without showing permission dialog
  Future<bool> canCollectAdvertisingId() async {
    try {
      if (Platform.isIOS) {
        final status = await AppTrackingTransparency.trackingAuthorizationStatus;
        return status == TrackingStatus.authorized;
      }
      
      if (Platform.isAndroid) {
        final isLimitAdTrackingEnabled = await AdvertisingId.isLimitAdTrackingEnabled;
        // Handle null case - treat null as "limit ad tracking enabled" (more restrictive)
        return !(isLimitAdTrackingEnabled ?? true);
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking advertising ID availability: $e');
      return false;
    }
  }

  /// Get advertising ID if permission is already granted
  Future<String?> getAdvertisingId() async {
    try {
      if (await canCollectAdvertisingId()) {
        return await AdvertisingId.id(true);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting advertising ID: $e');
      return null;
    }
  }

  /// Check if iOS system-level tracking setting is enabled (iOS only)
  /// This helps identify if "Allow Apps to Request to Track" is disabled
  Future<bool> isSystemTrackingEnabled() async {
    if (!Platform.isIOS) return true; // Android doesn't have this restriction
    
    try {
      // If we can get a status that's not restricted, the system setting is likely enabled
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      
      // If status is restricted, it might indicate system-level blocking
      // Note: This is not a perfect check, as restricted can also mean parental controls
      return status != TrackingStatus.restricted;
    } catch (e) {
      debugPrint('Error checking system tracking setting: $e');
      return false;
    }
  }
}

class TrackingPermissionResult {
  final bool isGranted;
  final String? advertisingId;
  final String platform;
  final String idType;
  final String? errorMessage;

  TrackingPermissionResult({
    required this.isGranted,
    required this.advertisingId,
    required this.platform,
    required this.idType,
    this.errorMessage,
  });

  @override
  String toString() {
    return 'TrackingPermissionResult(isGranted: $isGranted, advertisingId: $advertisingId, platform: $platform, idType: $idType, errorMessage: $errorMessage)';
  }
}
