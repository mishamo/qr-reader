import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  GoogleSignInAccount? _currentUser;
  GoogleSignInAuthentication? _currentAuth;
  
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> initialize() async {
    await GoogleSignIn.instance.initialize(
      scopes: [
        'email',
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive.file',
      ],
    );
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
      _currentUser = await GoogleSignIn.instance.signIn();
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
  }

  Future<sheets.SheetsApi?> getSheetsApi() async {
    try {
      if (_currentAuth == null) {
        if (_currentUser != null) {
          _currentAuth = await _currentUser!.authentication;
        } else {
          print('No user signed in');
          return null;
        }
      }

      // Create OAuth2 credentials
      final credentials = auth.AccessCredentials(
        auth.AccessToken(
          'Bearer',
          _currentAuth!.accessToken!,
          DateTime.now().add(const Duration(hours: 1)),
        ),
        null,
        [
          'https://www.googleapis.com/auth/spreadsheets',
          'https://www.googleapis.com/auth/drive.file',
        ],
      );

      // Create authenticated HTTP client
      final httpClient = auth.authenticatedClient(http.Client(), credentials);
      
      return sheets.SheetsApi(httpClient);
    } catch (e) {
      print('Error getting Sheets API: $e');
      return null;
    }
  }
}