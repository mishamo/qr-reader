import 'package:googleapis/sheets/v4.dart' as sheets;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class SheetsService {
  static final SheetsService _instance = SheetsService._internal();
  factory SheetsService() => _instance;
  SheetsService._internal();

  final AuthService _authService = AuthService();
  String? _activeSpreadsheetId;
  String? _activeSpreadsheetName;

  String? get activeSpreadsheetId => _activeSpreadsheetId;
  String? get activeSpreadsheetName => _activeSpreadsheetName;

  Future<void> loadActiveSheet() async {
    final prefs = await SharedPreferences.getInstance();
    _activeSpreadsheetId = prefs.getString('active_spreadsheet_id');
    _activeSpreadsheetName = prefs.getString('active_spreadsheet_name');
  }

  Future<void> setActiveSheet(String id, String name) async {
    _activeSpreadsheetId = id;
    _activeSpreadsheetName = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_spreadsheet_id', id);
    await prefs.setString('active_spreadsheet_name', name);
  }

  Future<List<SpreadsheetInfo>> listSpreadsheets() async {
    try {
      final sheetsApi = await _authService.getSheetsApi();
      if (sheetsApi == null) return [];
      
      // Get authenticated client for Drive API
      final driveApi = drive.DriveApi(sheetsApi.context.client);
      final fileList = await driveApi.files.list(
        q: "mimeType='application/vnd.google-apps.spreadsheet'",
        $fields: 'files(id, name, createdTime, modifiedTime)',
        orderBy: 'modifiedTime desc',
      );

      return fileList.files?.map((file) {
        return SpreadsheetInfo(
          id: file.id!,
          name: file.name!,
          createdTime: file.createdTime,
          modifiedTime: file.modifiedTime,
        );
      }).toList() ?? [];
    } catch (e) {
      print('Error listing spreadsheets: $e');
      return [];
    }
  }

  Future<String?> createSpreadsheet(String name) async {
    try {
      final sheetsApi = await _authService.getSheetsApi();
      if (sheetsApi == null) return null;

      final spreadsheet = sheets.Spreadsheet()
        ..properties = (sheets.SpreadsheetProperties()..title = name)
        ..sheets = [
          sheets.Sheet()
            ..properties = (sheets.SheetProperties()
              ..title = 'Scans'
              ..gridProperties = (sheets.GridProperties()
                ..rowCount = 1000
                ..columnCount = 10))
        ];

      final response = await sheetsApi.spreadsheets.create(spreadsheet);
      final spreadsheetId = response.spreadsheetId;

      if (spreadsheetId != null) {
        // Add headers
        await sheetsApi.spreadsheets.values.update(
          sheets.ValueRange()..values = [
            ['Timestamp', 'Name', 'Email', 'Company', 'Role', 'Phone', 'Notes', 'Scanned By']
          ],
          spreadsheetId,
          'Scans!A1:H1',
          valueInputOption: 'RAW',
        );

        await setActiveSheet(spreadsheetId, name);
      }

      return spreadsheetId;
    } catch (e) {
      print('Error creating spreadsheet: $e');
      return null;
    }
  }

  Future<bool> appendScanData(Map<String, String> scanData) async {
    if (_activeSpreadsheetId == null) {
      print('No active spreadsheet');
      return false;
    }

    try {
      final sheetsApi = await _authService.getSheetsApi();
      if (sheetsApi == null) return false;

      final now = DateTime.now().toIso8601String();
      final userEmail = _authService.currentUser?.email ?? 'Unknown';

      final values = [
        [
          now,
          scanData['name'] ?? '',
          scanData['email'] ?? '',
          scanData['company'] ?? '',
          scanData['role'] ?? '',
          scanData['phone'] ?? '',
          scanData['notes'] ?? '',
          userEmail,
        ]
      ];

      await sheetsApi.spreadsheets.values.append(
        sheets.ValueRange()..values = values,
        _activeSpreadsheetId!,
        'Scans!A:H',
        valueInputOption: 'RAW',
      );

      return true;
    } catch (e) {
      print('Error appending data: $e');
      return false;
    }
  }

  Future<String?> getSpreadsheetUrl() async {
    if (_activeSpreadsheetId == null) return null;
    return 'https://docs.google.com/spreadsheets/d/$_activeSpreadsheetId';
  }
}

class SpreadsheetInfo {
  final String id;
  final String name;
  final DateTime? createdTime;
  final DateTime? modifiedTime;

  SpreadsheetInfo({
    required this.id,
    required this.name,
    this.createdTime,
    this.modifiedTime,
  });
}