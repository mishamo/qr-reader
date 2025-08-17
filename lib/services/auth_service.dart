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
  GoogleSignInTokenData? _currentTokens;
  http.Client? _httpClient;
  
  static const List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/spreadsheets',
    'https://www.googleapis.com/auth/drive.file',
  ];
  
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      clientId: '65444604303-msum8l55m5evbau52mfcdcsb7e4o8f1j.apps.googleusercontent.com',
    );
    
    // Listen to authentication events
    GoogleSignIn.instance.authenticationEvents.listen((event) async {
      final user = switch (event) {
        GoogleSignInAuthenticationEventSignIn() => event.user,
        GoogleSignInAuthenticationEventSignOut() => null,
      };
      
      _currentUser = user;
      if (user != null) {
        // Get authorization for scopes
        final authorization = await user.authorizationClient.authorizationForScopes(_scopes);
        _currentTokens = authorization?.tokenData;
      } else {
        _currentTokens = null;
      }
    }).onError((error) {
      print('Authentication error: $error');
      _currentUser = null;
      _currentTokens = null;
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
        if (_currentUser != null && _currentTokens == null) {
          final authorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
          _currentTokens = authorization?.tokenData;
          
          // If not authorized for all scopes, request them
          if (_currentTokens == null) {
            final newAuth = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
            _currentTokens = newAuth?.tokenData;
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
      // Use authenticate() for v7
      await GoogleSignIn.instance.authenticate();
      // The authentication event listener will handle setting _currentUser
      // Wait a bit for the event to be processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Ensure we have authorization for our scopes
      if (_currentUser != null) {
        final authorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
        _currentTokens = authorization?.tokenData;
        
        // If not authorized for all scopes, request them
        if (_currentTokens == null) {
          final newAuth = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
          _currentTokens = newAuth?.tokenData;
        }
        
        print('Signed in as: ${_currentUser!.email}');
      }
      
      return _currentUser;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    _currentUser = null;
    _currentTokens = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<http.Client?> getAuthenticatedClient() async {
    try {
      if (_currentTokens == null) {
        if (_currentUser != null) {
          // Try to get authorization
          final authorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
          _currentTokens = authorization?.tokenData;
          
          if (_currentTokens == null) {
            // Request authorization if not available
            final newAuth = await _currentUser!.authorizationClient.authorizeScopes(_scopes);
            _currentTokens = newAuth?.tokenData;
          }
        }
        
        if (_currentTokens == null) {
          print('No tokens available');
          return null;
        }
      }

      // Close previous client if exists
      _httpClient?.close();

      // Create OAuth2 credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          _currentTokens!.accessToken,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
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