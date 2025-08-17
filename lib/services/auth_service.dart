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
  
  GoogleSignInAccount? get currentUser => _currentUser;
  List<String> get debugLogs => _debugLogs;
  String? get lastError => _lastError;
  
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
      _log('Using google-services.json configuration on Android');
      _log('Server Client ID (Web OAuth): 65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com');
      _log('Scopes: ${_scopes.join(", ")}}');
      
      // On Android with google-services.json, we should NOT provide clientId
      // Only serverClientId is needed (using the Web OAuth client ID)
      await GoogleSignIn.instance.initialize(
        serverClientId: '65444604303-mf6a3k7ibmrnrsuido8a9983nge7rqfh.apps.googleusercontent.com',
      );
      
      _log('Google Sign-In initialized successfully');
    } catch (e, stackTrace) {
      _lastError = 'Initialize failed: $e';
      _log('ERROR in initialize: $e');
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
      _log('Starting sign-in process...');
      _log('Package name: com.mishamo.qr_scanner');
      _log('Using authenticate() method (Google Sign-In v7)');
      
      // Use authenticate() for v7
      await GoogleSignIn.instance.authenticate();
      _log('authenticate() completed - waiting for event processing');
      
      // The authentication event listener will handle setting _currentUser
      // Wait a bit for the event to be processed
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (_currentUser == null) {
        _lastError = 'No user after authentication - check OAuth client configuration';
        _log('ERROR: _currentUser is null after authenticate()');
        _log('Possible issues:');
        _log('1. Wrong OAuth client type (should be Web Application)');
        _log('2. Package name mismatch');
        _log('3. SHA-1 fingerprint not registered');
        return null;
      }
      
      // Ensure we have authorization for our scopes
      _log('User available, checking authorization...');
      _currentAuthorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
      
      // If not authorized for all scopes, request them
      if (_currentAuthorization == null) {
        _log('Not authorized for scopes, requesting...');
        _currentAuthorization = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
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