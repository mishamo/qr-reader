import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(GoogleSignInAccount) onSignIn;

  const LoginScreen({
    super.key,
    required this.onSignIn,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningIn = false;
  bool _showDebugConsole = false;
  final ScrollController _debugScrollController = ScrollController();

  Future<void> _handleSignIn() async {
    setState(() {
      _isSigningIn = true;
      _showDebugConsole = true; // Auto-show debug console when signing in
    });

    try {
      final user = await _authService.signIn();
      if (user != null) {
        widget.onSignIn(user);
      } else {
        if (mounted) {
          final error = _authService.lastError ?? 'Sign in cancelled or failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exception: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSigningIn = false;
        });
        // Scroll debug console to bottom to show latest logs
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_debugScrollController.hasClients) {
            _debugScrollController.animateTo(
              _debugScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Main content
              Expanded(
                flex: _showDebugConsole ? 1 : 1,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'QR Scanner',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Conference Badge Scanner',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                const Text(
                                  'Sign in to get started',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton.icon(
                                    onPressed: _isSigningIn ? null : _handleSignIn,
                                    icon: _isSigningIn
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Image.asset(
                                            'assets/google_logo.png',
                                            height: 24,
                                            width: 24,
                                            errorBuilder: (context, error, stackTrace) {
                                              return const Icon(Icons.login);
                                            },
                                          ),
                                    label: Text(
                                      _isSigningIn ? 'Signing in...' : 'Sign in with Google',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Your scans will be saved to Google Sheets',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Debug toggle button
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDebugConsole = !_showDebugConsole;
                            });
                          },
                          icon: Icon(
                            _showDebugConsole ? Icons.bug_report : Icons.bug_report_outlined,
                            color: Colors.white70,
                          ),
                          label: Text(
                            _showDebugConsole ? 'Hide Debug Console' : 'Show Debug Console',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                        // Configuration test button (only when debug console is visible)
                        if (_showDebugConsole) ...[
                          TextButton.icon(
                            onPressed: () async {
                              setState(() {});
                              await _authService.testConfiguration();
                              setState(() {});
                              // Scroll to bottom to show test results
                              Future.delayed(const Duration(milliseconds: 100), () {
                                if (_debugScrollController.hasClients) {
                                  _debugScrollController.animateTo(
                                    _debugScrollController.position.maxScrollExtent,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                  );
                                }
                              });
                            },
                            icon: const Icon(Icons.settings, color: Colors.white70),
                            label: const Text(
                              'Test Configuration',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _authService.toggleTestMode();
                              setState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test mode toggled - check debug console'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.science, color: Colors.white70),
                            label: const Text(
                              'Toggle Test Mode',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Debug console
              if (_showDebugConsole)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border(
                      top: BorderSide(
                        color: Colors.yellow.shade700,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.yellow.shade900,
                        child: Row(
                          children: [
                            const Icon(Icons.terminal, color: Colors.yellow, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Debug Console',
                              style: TextStyle(
                                color: Colors.yellow,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.yellow),
                              onPressed: () async {
                                final logs = _authService.debugLogs.join('\n');
                                final lastError = _authService.lastError;
                                final fullText = lastError != null 
                                    ? 'LAST ERROR:\n$lastError\n\nDEBUG LOGS:\n$logs'
                                    : 'DEBUG LOGS:\n$logs';
                                
                                await Clipboard.setData(ClipboardData(text: fullText));
                                
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Debug logs copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              },
                              tooltip: 'Copy all logs',
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear_all, color: Colors.yellow),
                              onPressed: () {
                                setState(() {
                                  _authService.debugLogs.clear();
                                });
                              },
                              tooltip: 'Clear logs',
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.yellow),
                              onPressed: () {
                                setState(() {
                                  _showDebugConsole = false;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _debugScrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount: _authService.debugLogs.length,
                          itemBuilder: (context, index) {
                            final log = _authService.debugLogs[index];
                            final isError = log.contains('ERROR');
                            final isSuccess = log.contains('SUCCESS');
                            final isWarning = log.contains('WARNING');
                            
                            Color textColor = Colors.white70;
                            if (isError) {
                              textColor = Colors.red.shade300;
                            } else if (isSuccess) {
                              textColor = Colors.green.shade300;
                            } else if (isWarning) {
                              textColor = Colors.orange.shade300;
                            }
                            
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: textColor,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_authService.lastError != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          color: Colors.red.shade900,
                          child: Text(
                            'Last Error: ${_authService.lastError}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}