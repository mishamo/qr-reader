import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/sheets_service.dart';

class ScannerScreen extends StatefulWidget {
  final Function(Map<String, String>) onScanComplete;
  final String? activeSheet;

  const ScannerScreen({
    super.key,
    required this.onScanComplete,
    this.activeSheet,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final SheetsService _sheetsService = SheetsService();
  MobileScannerController? _scannerController;
  bool _isScanning = false;
  bool _hasScanned = false;
  String? _lastScanResult;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_hasScanned) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    
    final String? code = barcodes.first.rawValue;
    if (code == null || code.isEmpty) return;
    
    // Prevent multiple scans of the same code
    if (code == _lastScanResult) return;
    
    setState(() {
      _hasScanned = true;
      _lastScanResult = code;
    });

    // Parse the QR code data
    final scanData = _parseQRCode(code);
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(scanData);
    
    if (confirmed == true) {
      // Save to Google Sheets
      final success = await _sheetsService.appendScanData(scanData);
      
      if (success) {
        widget.onScanComplete(scanData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Scan saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save scan'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    // Reset after a delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _hasScanned = false;
        });
      }
    });
  }

  Map<String, String> _parseQRCode(String code) {
    // Try to parse as key:value pairs
    final Map<String, String> data = {};
    
    // Check if it's a structured format (e.g., "Name:John Doe\nEmail:john@example.com")
    if (code.contains(':')) {
      final lines = code.split('\n');
      for (final line in lines) {
        final parts = line.split(':');
        if (parts.length >= 2) {
          final key = parts[0].trim().toLowerCase();
          final value = parts.sublist(1).join(':').trim();
          data[key] = value;
        }
      }
    } else {
      // If unstructured, just store as raw data
      data['raw'] = code;
    }
    
    return data;
  }

  Future<bool?> _showConfirmationDialog(Map<String, String> data) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Scan'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (data['name'] != null)
                  _buildDataRow('Name', data['name']!),
                if (data['email'] != null)
                  _buildDataRow('Email', data['email']!),
                if (data['company'] != null)
                  _buildDataRow('Company', data['company']!),
                if (data['role'] != null)
                  _buildDataRow('Role', data['role']!),
                if (data['phone'] != null)
                  _buildDataRow('Phone', data['phone']!),
                if (data['raw'] != null)
                  _buildDataRow('Data', data['raw']!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeSheet == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 64,
                color: Colors.orange,
              ),
              const SizedBox(height: 16),
              const Text(
                'No Sheet Selected',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please select or create a Google Sheet first',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Navigate to sheets tab
                  DefaultTabController.of(context)?.animateTo(1);
                },
                child: const Text('Go to Sheets'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _handleBarcode,
        ),
        // Overlay
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_hasScanned ? 0.8 : 0.3),
          ),
          child: Stack(
            children: [
              // Viewfinder
              Center(
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasScanned ? Colors.green : Colors.white,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Instructions
              Positioned(
                top: 100,
                left: 0,
                right: 0,
                child: Text(
                  _hasScanned ? 'Processing...' : 'Point at QR Code',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Torch button
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: FloatingActionButton(
                    onPressed: () {
                      _scannerController?.toggleTorch();
                    },
                    backgroundColor: Colors.white.withOpacity(0.8),
                    child: ValueListenableBuilder(
                      valueListenable: _scannerController!.torchState,
                      builder: (context, state, child) {
                        return Icon(
                          state == TorchState.on
                              ? Icons.flash_on
                              : Icons.flash_off,
                          color: Colors.black,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}