import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';
import 'sheets_screen.dart';
import 'scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final GoogleSignInAccount user;
  final VoidCallback onSignOut;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onSignOut,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final SheetsService _sheetsService = SheetsService();
  int _selectedIndex = 0;
  List<Map<String, String>> _recentScans = [];

  @override
  void initState() {
    super.initState();
    _loadSheetInfo();
  }

  Future<void> _loadSheetInfo() async {
    await _sheetsService.loadActiveSheet();
    setState(() {});
  }

  void _onScanComplete(Map<String, String> scanData) {
    setState(() {
      _recentScans.insert(0, scanData);
      if (_recentScans.length > 10) {
        _recentScans.removeLast();
      }
    });
  }

  void _onSheetChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      ScannerScreen(
        onScanComplete: _onScanComplete,
        activeSheet: _sheetsService.activeSpreadsheetName,
      ),
      SheetsScreen(
        onSheetChanged: _onSheetChanged,
      ),
      _buildProfilePage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_selectedIndex == 0 && _sheetsService.activeSpreadsheetName != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(
                  _sheetsService.activeSpreadsheetName!,
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.green.shade100,
              ),
            ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scanner',
          ),
          NavigationDestination(
            icon: Icon(Icons.table_chart),
            label: 'Sheets',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'QR Scanner';
      case 1:
        return 'Sheets';
      case 2:
        return 'Profile';
      default:
        return 'QR Scanner';
    }
  }

  Widget _buildProfilePage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: widget.user.photoUrl != null
                  ? NetworkImage(widget.user.photoUrl!)
                  : null,
              child: widget.user.photoUrl == null
                  ? Text(
                      widget.user.displayName?.substring(0, 1).toUpperCase() ?? 
                      widget.user.email.substring(0, 1).toUpperCase(),
                      style: const TextStyle(fontSize: 36),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.displayName ?? 'User',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              widget.user.email,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStatRow('Recent Scans', _recentScans.length.toString()),
                    const Divider(),
                    _buildStatRow(
                      'Active Sheet',
                      _sheetsService.activeSpreadsheetName ?? 'None',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                await _authService.signOut();
                widget.onSignOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(200, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }
}