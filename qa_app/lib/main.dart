import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alloy_sdk/alloy_sdk.dart';
import 'package:uuid/uuid.dart';
import 'cmp_mock_service.dart';
import 'tracking_permission_service.dart';

// Global UserIDs instance
late final UserIDs userIDs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user IDs globally
  const uuid = Uuid();
  userIDs = UserIDs(
    ssoUserID: uuid.v4(),
    externalIDs: {
      'testID': uuid.v4(),
    }
  );
  
  // Initialize Alloy SDK with development configuration
  await AlloySDK.instance.start(
    configuration: AlloyConfiguration(
      tenant: 'demo',
      env: AlloyEnvironment.staging,
      appID: 'qa-flutter-app',
      logLevel: AlloyLogLevel.debug,
    ),
  );
  
  runApp(const AlloyQAApp());
}

class AlloyQAApp extends StatelessWidget {
  const AlloyQAApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alloy SDK QA App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const QAHomePage(),
    );
  }
}

class QAHomePage extends StatefulWidget {
  const QAHomePage({super.key});

  @override
  State<QAHomePage> createState() => _QAHomePageState();
}

class _QAHomePageState extends State<QAHomePage> with TickerProviderStateMixin {
  late TabController _tabController;
  String _preferencesText = 'No preferences loaded';
  bool _isSDKInitialized = false;
  
  // Tracking permission state
  String _trackingPermissionStatus = 'Not requested';
  String? _advertisingId;
  bool _trackingPermissionGranted = false;
  
  // Consent change subscription
  StreamSubscription<dynamic>? _consentSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshPreferences();
    _checkTrackingPermissionStatus();
    _setupConsentListener();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _consentSubscription?.cancel();
    super.dispose();
  }

  void _refreshPreferences() async {
    try {
      final consentState = await CMPMockService.getCurrentConsentState();
      setState(() {
        _preferencesText = '[REAL IAB TCF PREFERENCES]\n'
            'Refreshed at ${DateTime.now()}\n'
            'IABTCF_TCString: ${consentState['IABTCF_TCString'] ?? 'Not set'}\n'
            'IABTCF_PurposeConsents: ${consentState['IABTCF_PurposeConsents'] ?? 'Not set'}\n'
            'IABTCF_VendorConsents: ${consentState['IABTCF_VendorConsents'] != null ? 'Set (length: ${consentState['IABTCF_VendorConsents'].toString().length})' : 'Not set'}\n\n'
            'Note: These are the actual IAB TCF values that the SDK reads.\n'
            'The SDK\'s consent state depends on these preference values.';
      });
    } catch (e) {
      setState(() {
        _preferencesText = '[ERROR LOADING PREFERENCES]\n'
            'Failed to load consent state: $e\n\n'
            'This may indicate platform channel issues.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Alloy SDK QA App'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'SDK Testing'),
            Tab(text: 'CMP Mock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildConsentTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Alloy SDK Testing',
            style: TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Test core SDK functionality',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 30),
          // SDK Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSDKInitialized ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _isSDKInitialized ? 'SDK Initialized' : 'SDK Not Initialized',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _isSDKInitialized ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          // SDK Action Buttons
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initializeSDK,
              icon: const Icon(Icons.power_settings_new),
              label: const Text('Initialize'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _getVisitorID,
              icon: const Icon(Icons.fingerprint),
              label: const Text('Get Visitor ID'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _trackPageView,
              icon: const Icon(Icons.web),
              label: const Text('Track Pageview'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchContextualData,
              icon: const Icon(Icons.data_usage),
              label: const Text('Fetch Contextual Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _fetchSegmentData,
              icon: const Icon(Icons.group),
              label: const Text('Fetch Segment Data'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _toggleTrackingPermission,
              icon: Icon(_trackingPermissionGranted ? Icons.toggle_on : Icons.toggle_off),
              label: Text(_trackingPermissionGranted ? 'Revoke Tracking Permission' : 'Request Tracking Permission'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _trackingPermissionGranted ? Colors.red : Colors.teal,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Tracking Permission Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tracking Permission Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _trackingPermissionGranted ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(_trackingPermissionStatus),
                  ],
                ),
                if (_advertisingId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Advertising ID: ${_advertisingId!.substring(0, 8)}...',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'CMP Mock (Real IAB TCF)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _setConsent,
                  child: const Text('Grant Consent'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _disableConsent,
                  child: const Text('Deny Consent'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _resetConsent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset All'),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _refreshPreferences,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'IAB TCF Preferences:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _preferencesText,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _checkTrackingPermissionStatus() async {
    try {
      final canCollect = await TrackingPermissionService.instance.canCollectAdvertisingId();
      final advertisingId = await TrackingPermissionService.instance.getAdvertisingId();
      
      setState(() {
        _trackingPermissionGranted = canCollect;
        _advertisingId = advertisingId;
        
        if (canCollect && advertisingId != null) {
          _trackingPermissionStatus = 'Already granted';
        } else {
          _trackingPermissionStatus = 'Not granted';
        }
      });
    } catch (e) {
      setState(() {
        _trackingPermissionStatus = 'Check failed: $e';
        _trackingPermissionGranted = false;
        _advertisingId = null;
      });
    }
  }

  void _setupConsentListener() {
    // Listen to consent state changes (much better than raw TCString)
    _consentSubscription = AlloySDK.instance.consentStateStream.listen((consentState) async {      
      // Re-initialize SDK when consent is granted
      if (consentState == ConsentState.ready) {
        try {
          final success = await AlloySDK.instance.initialize(userIDs: userIDs);
          setState(() {
            _isSDKInitialized = success;
          });
          
          // Refresh preferences to show updated values
          _refreshPreferences();
        } catch (e) {
          setState(() {
            _isSDKInitialized = false;
          });
        }
      } else {
        // Consent was denied or not initialized
        setState(() {
          _isSDKInitialized = false;
        });
      }
    });
  }

  // Tracking Permission Methods
  void _toggleTrackingPermission() async {
    try {
      if (_trackingPermissionGranted) {
        // Revoke tracking permission (simulate by resetting state)
        setState(() {
          _trackingPermissionStatus = 'Revoked (simulated)';
          _trackingPermissionGranted = false;
          _advertisingId = null;
        });

        if (mounted) {
          _showAlert(
            'Tracking Permission Revoked',
            'Tracking permission has been revoked.\n\n'
            'Note: On iOS, users must go to Settings > Privacy & Security > Tracking to actually revoke permission. '
            'On Android, users must enable "Limit Ad Tracking" in device settings.\n\n'
            'This is a simulated revocation for testing purposes.',
          );
        }
      } else {
        // Request tracking permission
        setState(() {
          _trackingPermissionStatus = 'Requesting...';
        });

        final result = await TrackingPermissionService.instance.requestTrackingPermission();
        
        setState(() {
          _trackingPermissionGranted = result.isGranted;
          _advertisingId = result.advertisingId;
          
          if (result.isGranted) {
            _trackingPermissionStatus = 'Granted (${result.platform} ${result.idType})';
          } else {
            _trackingPermissionStatus = 'Denied (${result.platform})';
          }
        });

        if (mounted) {
          String dialogMessage = 'Status: ${result.isGranted ? 'Granted' : 'Denied'}\n'
              'Platform: ${result.platform}\n'
              'ID Type: ${result.idType}\n'
              'Advertising ID: ${result.advertisingId ?? 'Not available'}\n';
          
          if (result.errorMessage != null) {
            dialogMessage += '\nDetails: ${result.errorMessage}';
          }
          
          // Add iOS-specific guidance if tracking was denied
          if (Platform.isIOS && !result.isGranted) {
            dialogMessage += '\n\nℹ️ iOS Tracking Info:\n'
                '• If no dialog appeared, check Settings > Privacy & Security > Tracking\n'
                '• Enable "Allow Apps to Request to Track" and restart the app\n'
                '• If previously denied, you must reset in Settings > Privacy & Security > Tracking > [App Name]';
          }
          
          _showAlert('Tracking Permission Result', dialogMessage);
        }
      }
    } catch (e) {
      setState(() {
        _trackingPermissionStatus = 'Error occurred';
        _trackingPermissionGranted = false;
        _advertisingId = null;
      });
      
      if (mounted) {
        _showAlert('Tracking Permission Error', 'Error: $e');
      }
    }
  }

  // SDK Action Methods
  void _initializeSDK() async {
    try {

      final success = await AlloySDK.instance.initialize(userIDs: userIDs);
      
      setState(() {
        _isSDKInitialized = success;
      });
      
      if (mounted) {
        String message = success 
            ? 'SDK initialized successfully!\n\nThe SDK automatically collected advertising ID if tracking permissions are granted. Check debug logs for details.' 
            : 'SDK initialization failed';
        
        _showAlert('Initialize Result', message);
      }
    } catch (e) {
      setState(() {
        _isSDKInitialized = false;
      });
      
      if (mounted) {
        _showAlert('Initialize Error', 'Error: $e');
      }
    }
  }

  void _getVisitorID() async {
    try {
      final visitorID = await AlloySDK.instance.visitorID;
      if (mounted) {
        _showAlert(
          'Visitor ID',
          visitorID ?? 'No visitor ID available',
        );
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Visitor ID Error', 'Error: $e');
      }
    }
  }

  void _trackPageView() async {
    try {
      final sampleUrls = [
        'https://example.com/home',
        'https://www.blick.ch/news/politik/article123',
        'https://www.blick.ch/',
      ];
      
      final url = sampleUrls[DateTime.now().millisecondsSinceEpoch % sampleUrls.length];
      
      final parameters = PageViewParameters(
        pageURL: url,
        referer: 'https://example.com',
        contentID: 'test-content-id',
        logicalPath: '/test/path',
        customTrackingAttributes: {
          'content_type': 'article',
          'category': 'news',
        },
      );
      
      await AlloySDK.instance.trackPageView(parameters: parameters);
      
      if (mounted) {
        _showAlert(
          'Track Pageview', 
          'SDK tracking call completed for: $url\n\n'
          'Note: Check the debug logs to verify if the event was actually sent. '
          'If consent is not granted, the TrackingService will log "Ignoring page view event".'
        );
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Track Pageview Error', 'Error: $e');
      }
    }
  }

  void _fetchContextualData() async {
    try {
      final sampleUrls = [
        'https://example.com/home',
        'https://www.blick.ch/news/politik/article123',
        'https://www.blick.ch/',
      ];
      
      final url = sampleUrls[DateTime.now().millisecondsSinceEpoch % sampleUrls.length];
      
      final response = await AlloySDK.instance.fetchContextualData(url: url);
      
      if (mounted) {
        final details = '''
Canonical ID: ${response.canonicalID ?? 'N/A'}
Brand Safety: ${response.isBrandsafe ?? 'N/A'}
Attribution: ${response.attribution ?? 'N/A'}
IAB Categories: ${response.iabs?.join(', ') ?? 'N/A'}
Topics: ${response.topics?.join(', ') ?? 'N/A'}
        ''';
        _showAlert('Contextual Data', details);
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Contextual Data Error', 'Error: $e');
      }
    }
  }

  void _fetchSegmentData() async {
    try {
      final response = await AlloySDK.instance.fetchSegmentData();
      
      if (mounted) {
        final segmentIds = response.segmentIds.isEmpty 
            ? 'No segments found'
            : response.segmentIds.join(', ');
        _showAlert('Segment Data', 'Segment IDs: $segmentIds');
      }
    } catch (e) {
      if (mounted) {
        _showAlert('Segment Data Error', 'Error: $e');
      }
    }
  }

  // Consent Management Methods
  void _setConsent() async {
    try {
      await CMPMockService.grantConsent();
      _refreshPreferences(); // Refresh to show new values
      _showAlert(
        'CMP Mock: Consent Granted', 
        'Real IAB TCF preference values have been set to indicate user consent.\n\n'
        'The SDK will now read these values and allow tracking. '
        'Check the debug logs to see the consent state change in real-time.'
      );
    } catch (e) {
      _showAlert('Error', 'Failed to grant consent: $e');
    }
  }

  void _disableConsent() async {
    try {
      await CMPMockService.denyConsent();
      _refreshPreferences(); // Refresh to show cleared values
      _showAlert(
        'CMP Mock: Consent Denied', 
        'IAB TCF preference values have been cleared to indicate no consent.\n\n'
        'The SDK will now block tracking and log "Ignoring page view event" '
        'when tracking methods are called.'
      );
    } catch (e) {
      _showAlert('Error', 'Failed to deny consent: $e');
    }
  }

  void _resetConsent() async {
    try {
      await CMPMockService.resetConsent();
      _refreshPreferences(); // Refresh to show cleared values
      _showAlert(
        'CMP Mock: Reset', 
        'All IAB TCF preference values have been cleared.\n\n'
        'This simulates a user who has not yet interacted with a CMP. '
        'The SDK will treat this as no consent given.'
      );
    } catch (e) {
      _showAlert('Error', 'Failed to reset consent: $e');
    }
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
