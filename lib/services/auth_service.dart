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
  GoogleSignInAuthentication? _currentAuth;
  http.Client? _httpClient;
  
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      clientId: '65444604303-msum8l55m5evbau52mfcdcsb7e4o8f1j.apps.googleusercontent.com',
      scopes: [
        'email',
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );
    
    // Listen to authentication events
    GoogleSignIn.instance.authenticationEvents.listen((account) {
      _currentUser = account;
      if (account != null) {
        account.authentication.then((auth) {
          _currentAuth = auth;
        });
      } else {
        _currentAuth = null;
      }
    });
  }

  Future<GoogleSignInAccount?> tryAutoSignIn() async {
    try {
      // Try lightweight authentication (replaces signInSilently)
      final future = GoogleSignIn.instance.attemptLightweightAuthentication();
      if (future != null) {
        _currentUser = await future;
        if (_currentUser != null) {
          _currentAuth = await _currentUser!.authentication;
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
      _currentUser = await GoogleSignIn.instance.authenticate();
      if (_currentUser != null) {
        _currentAuth = await _currentUser!.authentication;
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
    _currentAuth = null;
    _httpClient?.close();
    _httpClient = null;
  }

  Future<http.Client?> getAuthenticatedClient() async {
    try {
      if (_currentAuth == null) {
        if (_currentUser != null) {
          _currentAuth = await _currentUser!.authentication;
        } else {
          print('No user signed in');
          return null;
        }
      }

      // Close previous client if exists
      _httpClient?.close();

      // Create OAuth2 credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          _currentAuth!.accessTokenString!,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [
          'https://www.googleapis.com/auth/spreadsheets',
          'https://www.googleapis.com/auth/drive.file',
        ],
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