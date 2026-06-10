import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import '../services/hid_scanner_service.dart';

class HIDScanner extends StatefulWidget {
  final Function(String) onScanDetected;
  final bool enabled;

  const HIDScanner({
    super.key,
    required this.onScanDetected,
    this.enabled = true,
  });

  @override
  State<HIDScanner> createState() => _HIDScannerState();
}

class _HIDScannerState extends State<HIDScanner> {
  final HIDScannerService _scannerService = HIDScannerService();
  bool _isConnected = false;
  bool _isScanning = false;
  String? _lastScan;
  DateTime? _lastScanTime;
  StreamSubscription<String>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  @override
  void didUpdateWidget(HIDScanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startScanner();
      } else {
        _stopScanner();
      }
    }
  }

  @override
  void dispose() {
    _stopScanner();
    super.dispose();
  }

  void _initializeScanner() {
    if (widget.enabled) {
      _startScanner();
    }
  }

  void _startScanner() {
    _scanSubscription = _scannerService.scanStream.listen((scanData) {
      setState(() {
        _lastScan = scanData;
        _lastScanTime = DateTime.now();
        _isScanning = false;
      });

      widget.onScanDetected(scanData);

      // Reset scanning state after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isScanning = false;
          });
        }
      });
    });

    _scannerService.startListening();
    setState(() {
      _isConnected = true;
    });
  }

  void _stopScanner() {
    _scanSubscription?.cancel();
    _scannerService.stopListening();
    setState(() {
      _isConnected = false;
      _isScanning = false;
    });
  }

  void _simulateScan() {
    setState(() {
      _isScanning = true;
    });

    // Simulate a scan after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isScanning) {
        final simulatedData =
            'HID_SCAN_${DateTime.now().millisecondsSinceEpoch}';
        setState(() {
          _lastScan = simulatedData;
          _lastScanTime = DateTime.now();
          _isScanning = false;
        });
        widget.onScanDetected(simulatedData);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatusCard(),
          const SizedBox(height: 20),
          _buildLastScan(),
          const SizedBox(height: 20),
          _buildInstructions(),
          const SizedBox(height: 20),
          _buildTestButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isConnected ? Colors.green.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.usb,
            color: _isConnected ? Colors.green.shade600 : Colors.grey.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HID Scanner',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                _isConnected ? 'Connected - Ready to scan' : 'Disconnected',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: _isConnected
                      ? Colors.green.shade600
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: widget.enabled,
          onChanged: (value) {
            // Parent controls this state
          },
          activeThumbColor: Colors.orange.shade600,
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isScanning ? Colors.orange.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isScanning ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          if (_isScanning)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(
              _isConnected ? Icons.check_circle : Icons.radio_button_unchecked,
              color:
                  _isConnected ? Colors.green.shade600 : Colors.grey.shade600,
              size: 16,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isScanning
                  ? 'Scanning... Point scanner at QR/RFID tag'
                  : _isConnected
                      ? 'Ready - Scan QR code or RFID tag'
                      : 'Enable scanner to start',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _isScanning
                    ? Colors.orange.shade800
                    : _isConnected
                        ? Colors.green.shade800
                        : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastScan() {
    if (_lastScan == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.history, color: Colors.grey.shade600, size: 16),
            const SizedBox(width: 12),
            Text(
              'No scans yet',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 12),
              Text(
                'Last Scan:',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _lastScan!,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade800,
            ),
          ),
          if (_lastScanTime != null)
            Text(
              '${_lastScanTime!.hour.toString().padLeft(2, '0')}:${_lastScanTime!.minute.toString().padLeft(2, '0')}:${_lastScanTime!.second.toString().padLeft(2, '0')}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
              const SizedBox(width: 8),
              Text(
                'How to use HID Scanner:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            '1. Connect USB/Bluetooth QR or RFID scanner',
            '2. Ensure scanner is in keyboard mode (HID)',
            '3. Point scanner at QR code or RFID tag',
            '4. Scanner will automatically input the code',
            '5. System detects and processes the scan'
          ].map((instruction) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  instruction,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.blue.shade800,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _simulateScan,
        icon: const Icon(Icons.play_arrow),
        label: Text(
          'Test Scanner (Simulate)',
          style: GoogleFonts.poppins(),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
