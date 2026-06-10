import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:provider/provider.dart';
import '../providers/student_provider.dart';

class RfidScanner extends StatefulWidget {
  const RfidScanner({super.key});

  @override
  State<RfidScanner> createState() => _RfidScannerState();
}

class _RfidScannerState extends State<RfidScanner> {
  bool _isNfcAvailable = false;
  bool _isScanning = false;
  String? _lastScannedId;

  @override
  void initState() {
    super.initState();
    _checkNfcAvailability();
  }

  Future<void> _checkNfcAvailability() async {
    final isAvailable = await NfcManager.instance.isAvailable();
    setState(() {
      _isNfcAvailable = isAvailable;
    });
  }

  Future<void> _startNfcScanning() async {
    if (!_isNfcAvailable) return;

    setState(() {
      _isScanning = true;
    });

    try {
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        final id = tag.data['mifare']['identifier'] as List<int>?;
        if (id != null) {
          final hexId = id
              .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
              .join(':');

          setState(() {
            _lastScannedId = hexId;
          });

          // Process the scanned RFID ID
          await _processRfidId(hexId);

          // Stop scanning after successful read
          await NfcManager.instance.stopSession();
          setState(() {
            _isScanning = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopNfcScanning() async {
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      // Ignore errors when stopping
    }

    setState(() {
      _isScanning = false;
    });
  }

  Future<void> _processRfidId(String rfidId) async {
    final provider = context.read<StudentProvider>();
    await provider.checkStudentId(rfidId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RFID Scanned: $rfidId'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.nfc,
                color: _isNfcAvailable ? Colors.green : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'RFID Scanner',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!_isNfcAvailable)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'NFC not available on this device',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              _isScanning
                  ? 'Hold RFID card near device...'
                  : 'Ready to scan RFID cards',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            if (_lastScannedId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Last Scanned: $_lastScannedId',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isScanning ? _stopNfcScanning : _startNfcScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isScanning ? Colors.red : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopNfcScanning();
    super.dispose();
  }
}
