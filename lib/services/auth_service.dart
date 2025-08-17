import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  GoogleSignInAccount? _currentUser;
  GoogleSignInClientAuthorization? _currentAuthorization;
  http.Client? _httpClient;
  
  // Debug logging
  final List<String> _debugLogs = [];
  String? _lastError;
  
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];
  
  // Test mode flag
  static bool _testModeNoScopes = false;
  
  GoogleSignInAccount? get currentUser => _currentUser;
  List<String> get debugLogs => _debugLogs;
  String? get lastError => _lastError;
  
  // Toggle test mode
  void toggleTestMode() {
    _testModeNoScopes = !_testModeNoScopes;
    _log('TEST MODE TOGGLED: ${_testModeNoScopes ? "ON - Skipping scopes" : "OFF - Using normal scopes"}');
  }
  
  // Test configuration method
  Future<void> testConfiguration() async {
    _log('=== TESTING CONFIGURATION ===');
    try {
      _log('1. Testing GoogleSignIn instance properties...');
      _log('   - Can create instance: YES');
      
      _log('2. Attempting to check current authentication state...');
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) {
        _log('   - Lightweight auth available, attempting...');
        await future;
        _log('   - Lightweight auth completed');
      } else {
        _log('   - No existing authentication found (expected for first run)');
      }
      
      _log('3. Configuration appears valid');
      _log('=== END CONFIGURATION TEST ===');
    } catch (e) {
      _log('ERROR during configuration test: $e');
      _log('This might indicate google-services.json issues');
    }
  }
  
  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $message';
    _debugLogs.add(logMessage);
    print(logMessage);
    if (_debugLogs.length > 100) {
      _debugLogs.removeAt(0);
    }
  }

  Future<void> initialize() async {
    try {
      _log('Initializing Google Sign-In...');
      _log('Platform: ${defaultTargetPlatform.toString()}');
      _log('Debug mode: ${kDebugMode ? "YES" : "NO"}');
      _log('Release mode: ${kReleaseMode ? "YES" : "NO"}');
      
      if (defaultTargetPlatform == TargetPlatform.android) {
        _log('Android detected - trying WITHOUT google-services.json');
        _log('Using direct OAuth configuration like Fyne did');
        _log('Web OAuth Client ID: 65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com');
        
        // Try with both clientId AND serverClientId to override google-services.json
        await GoogleSignIn.instance.initialize(
          clientId: '65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com',
          serverClientId: '65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com',
        );
        
        _log('Initialize() completed with direct OAuth config');
      } else {
        _log('Non-Android platform - using clientId');
        await GoogleSignIn.instance.initialize(
          clientId: '65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com',
        );
      }
      
      _log('Scopes to be requested: ${_scopes.join(", ")}}');
      _log('Google Sign-In initialization complete');
    } catch (e, stackTrace) {
      _lastError = 'Initialize failed: $e';
      _log('ERROR in initialize: $e');
      _log('Error type: ${e.runtimeType}');
      _log('Stack trace: $stackTrace');
      rethrow;
    }
    
    // Listen to authentication events
    GoogleSignIn.instance.authenticationEvents.listen((event) async {
      _log('Authentication event received: ${event.runtimeType}');
      
      final user = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };
      
      _currentUser = user;
      if (user != null) {
        _log('User signed in: ${user.email}');
        _log('User ID: ${user.id}');
        _log('Display name: ${user.displayName}');
        
        // Get authorization for scopes
        try {
          _log('Requesting authorization for scopes...');
          _currentAuthorization = await user.authorizationClient.authorizationForScopes(_scopes);
          if (_currentAuthorization != null) {
            _log('Authorization obtained successfully');
            _log('Has access token: ${_currentAuthorization!.accessToken.isNotEmpty}');
          } else {
            _log('Authorization is null - requesting scope authorization');
            _currentAuthorization = await user.authorizationClient.authorizeScopes(_scopes);
          }
        } catch (e) {
          _lastError = 'Authorization failed: $e';
          _log('ERROR getting authorization: $e');
        }
      } else {
        _log('User signed out');
        _currentAuthorization = null;
      }
    }).onError((error, stackTrace) {
      _lastError = 'Authentication stream error: $error';
      _log('ERROR in authentication stream: $error');
      _log('Stack trace: $stackTrace');
      _currentUser = null;
      _currentAuthorization = null;
    });
  }

  Future<GoogleSignInAccount?> tryAutoSignIn() async {
    try {
      // Try lightweight authentication (replaces signInSilently)
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) {
        await future;
        // The authentication event listener will handle setting _currentUser
        // Wait a bit for the event to be processed
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Ensure we have authorization for our scopes
        if (_currentUser != null && _currentAuthorization == null) {
          _currentAuthorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
          
          // If not authorized for all scopes, request them
          if (_currentAuthorization == null) {
            _currentAuthorization = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
          }
        }
        
        return _currentUser;
      }
      return null;
    } catch (e) {
      print('Auto sign-in failed: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      _lastError = null;
      _log('=== SIGN-IN ATTEMPT STARTING ===');
      _log('Platform: ${defaultTargetPlatform.toString()}');
      _log('Package name expected: com.mishamo.qr_scanner');
      _log('Current user before sign-in: ${_currentUser?.email ?? "none"}');
      
      // Check if already initialized
      _log('Checking GoogleSignIn instance state...');
      _log('Using authenticate() method (Google Sign-In v7)');
      
      // Log configuration being used
      _log('Configuration check:');
      _log('- serverClientId configured: YES');
      _log('- google-services.json should contain both Web and Android OAuth clients');
      _log('- Expected SHA-1: 85:2E:B4:F6:03:61:AD:CD:D3:BE:12:AF:8A:B3:74:33:DF:98:8D:0A');
      
      // Use authenticate() for v7
      _log('Calling GoogleSignIn.instance.authenticate()...');
      _log('Current GoogleSignIn state before authenticate:');
      _log('- Has instance: ${GoogleSignIn.instance != null}');
      
      try {
        await GoogleSignIn.instance.authenticate();
        _log('authenticate() returned successfully (no exception)');
      } catch (authError) {
        _log('authenticate() threw immediate error: $authError');
        if (authError.toString().contains('[16]')) {
          _log('ERROR CODE 16 DETAILS:');
          _log('This is "Account reauth failed" - typically means:');
          _log('1. Scopes not yet propagated (can take up to 1 hour)');
          _log('2. OAuth consent screen needs to be in Production mode');
          _log('3. Need to wait for Google servers to update');
          _log('');
          _log('WORKAROUND: Try using a different Google account');
          _log('or wait 30-60 minutes for full propagation');
        }
        rethrow;
      }
      
      _log('Waiting for event processing...');
      
      // The authentication event listener will handle setting _currentUser
      // Wait a bit for the event to be processed
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_currentUser == null) {
        _lastError = 'No user after authentication';
        _log('ERROR: _currentUser is null after authenticate()');
        _log('=== TROUBLESHOOTING CHECKLIST ===');
        _log('1. In Google Cloud Console, verify:');
        _log('   - Android OAuth client exists with SHA-1: 85:2E:B4:F6:03:61:AD:CD:D3:BE:12:AF:8A:B3:74:33:DF:98:8D:0A');
        _log('   - Package name: com.mishamo.qr_scanner');
        _log('   - Web OAuth client exists');
        _log('2. OAuth consent screen:');
        _log('   - Status: Testing or Production');
        _log('   - Test users added (if Testing)');
        _log('3. google-services.json contains:');
        _log('   - Both Android (type 1) and Web (type 3) OAuth clients');
        return null;
      }
      
      // Ensure we have authorization for our scopes
      if (!_testModeNoScopes) {
        _log('User available, checking authorization...');
        _currentAuthorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
        
        // If not authorized for all scopes, request them
        if (_currentAuthorization == null) {
          _log('Not authorized for scopes, requesting...');
          _currentAuthorization = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
        }
      } else {
        _log('TEST MODE: Skipping scope authorization');
      }
      
      if (_currentAuthorization != null) {
        _log('SUCCESS: Signed in as: ${_currentUser!.email}');
        _log('Authorization token available: ${_currentAuthorization!.accessToken.isNotEmpty}');
      } else {
        _lastError = 'Failed to get authorization for required scopes';
        _log('ERROR: Could not get authorization');
      }
      
      return _currentUser;
    } catch (e, stackTrace) {
      _lastError = 'Sign-in exception: $e';
      _log('ERROR in signIn: $e');
      _log('Exception type: ${e.runtimeType}');
      _log('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
    _currentAuthorization = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<http.Client?> getAuthenticatedClient() async {
    try {
      if (_currentAuthorization == null) {
        if (_currentUser != null) {
          // Try to get authorization
          _currentAuthorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
          
          if (_currentAuthorization == null) {
            // Request authorization if not available
            _currentAuthorization = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
          }
        }
        
        if (_currentAuthorization == null) {
          print('No authorization available');
          return null;
        }
      }

      // Close previous client if exists
      _httpClient?.close();

      // Create OAuth2 credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          _currentAuthorization!.accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null, // idToken is not available in GoogleSignInClientAuthorization
        _scopes,
      );

      // Create authenticated HTTP client
      _httpClient = auth.authenticatedClient(http.Client(), credentials);
      return _httpClient;
    } catch (e) {
      print('Error getting authenticated client: $e');
      return null;
    }
  }

  Future<sheets.SheetsApi?> getSheetsApi() async {
    final client = await getAuthenticatedClient();
    return client != null ? sheets.SheetsApi(client) : null;
  }
  
  Future<drive.DriveApi?> getDriveApi() async {
    final client = await getAuthenticatedClient();
    return client != null ? drive.DriveApi(client) : null;
  }
}