import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/sheets_service.dart';

class SheetsScreen extends StatefulWidget {
  final VoidCallback onSheetChanged;

  const SheetsScreen({
    super.key,
    required this.onSheetChanged,
  });

  @override
  State<SheetsScreen> createState() => _SheetsScreenState();
}

class _SheetsScreenState extends State<SheetsScreen> {
  final SheetsService _sheetsService = SheetsService();
  List<SpreadsheetInfo> _spreadsheets = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSpreadsheets();
  }

  Future<void> _loadSpreadsheets() async {
    setState(() {
      _isLoading = true;
    });

    final sheets = await _sheetsService.listSpreadsheets();
    
    if (mounted) {
      setState(() {
        _spreadsheets = sheets;
        _isLoading = false;
      });
    }
  }

  Future<void> _createNewSheet() async {
    final nameController = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Sheet'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Sheet name',
            labelText: 'Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(context).pop(nameController.text);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      final sheetId = await _sheetsService.createSpreadsheet(name);
      
      if (sheetId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sheet created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSheetChanged();
        _loadSpreadsheets();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create sheet'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectSheet(SpreadsheetInfo sheet) async {
    await _sheetsService.setActiveSheet(sheet.id, sheet.name);
    widget.onSheetChanged();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${sheet.name}'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    }
  }

  Future<void> _openSheet(String sheetId) async {
    final url = Uri.parse('https://docs.google.com/spreadsheets/d/$sheetId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareSheet() async {
    final url = await _sheetsService.getSpreadsheetUrl();
    if (url != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Share Sheet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sheet URL:'),
              const SizedBox(height: 8),
              SelectableText(
                url,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'Share this link with your team. They need to:\n'
                '1. Sign in with their Google account\n'
                '2. Select this sheet in the app\n'
                '3. Start scanning!',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final url = Uri.parse(await _sheetsService.getSpreadsheetUrl() ?? '');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open in Browser'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSheetId = _sheetsService.activeSpreadsheetId;

    return Scaffold(
      body: Column(
        children: [
          if (activeSheetId != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text(
                  'Active: ${_sheetsService.activeSpreadsheetName}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: _shareSheet,
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new),
                      onPressed: () => _openSheet(activeSheetId),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton.icon(
              onPressed: _createNewSheet,
              icon: const Icon(Icons.add),
              label: const Text('Create New Sheet'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_spreadsheets.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.table_chart_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No sheets found',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a new sheet to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadSpreadsheets,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _spreadsheets.length,
                  itemBuilder: (context, index) {
                    final sheet = _spreadsheets[index];
                    final isActive = sheet.id == activeSheetId;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          Icons.table_chart,
                          color: isActive ? Colors.green : null,
                        ),
                        title: Text(
                          sheet.name,
                          style: TextStyle(
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: sheet.modifiedTime != null
                            ? Text(
                                'Modified: ${_formatDate(sheet.modifiedTime!)}',
                                style: const TextStyle(fontSize: 12),
                              )
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              const Chip(
                                label: Text('Active'),
                                backgroundColor: Colors.green,
                                labelStyle: TextStyle(color: Colors.white),
                              )
                            else
                              TextButton(
                                onPressed: () => _selectSheet(sheet),
                                child: const Text('Select'),
                              ),
                            IconButton(
                              icon: const Icon(Icons.open_in_new, size: 20),
                              onPressed: () => _openSheet(sheet.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}