import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/spreadsheets',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> tryAutoSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      print('Auto sign-in failed: $e');
      return null;
    }
  }

  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        print('Signed in as: ${account.email}');
      }
      return account;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<sheets.SheetsApi?> getSheetsApi() async {
    try {
      final httpClient = await _googleSignIn.authenticatedClient();
      if (httpClient == null) {
        print('Failed to get authenticated client');
        return null;
      }
      return sheets.SheetsApi(httpClient);
    } catch (e) {
      print('Error getting Sheets API: $e');
      return null;
    }
  }
}