import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/student_provider.dart';
import '../widgets/student_info_card.dart';
import '../widgets/rfid_scanner.dart';
import '../widgets/qr_generator.dart';
import '../widgets/web_qr_scanner.dart';
import '../widgets/hid_scanner.dart';

// Only import QR scanner for mobile platforms
import 'package:qr_code_scanner/qr_code_scanner.dart'
    if (dart.library.html) '../stubs/qr_code_scanner_stub.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = true;
  String? lastScannedCode;
  bool isProcessing = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange.shade50,
                Colors.amber.shade50,
                Colors.orange.shade100,
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildQrScannerTab(),
                      _buildRfidScannerTab(),
                      _buildHidScannerTab(),
                      _buildQrGeneratorTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.orange.shade600,
        labelColor: Colors.orange.shade600,
        unselectedLabelColor: Colors.grey.shade600,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w400,
          fontSize: 12,
        ),
        tabs: const [
          Tab(icon: Icon(Icons.qr_code_scanner), text: 'QR Scanner'),
          Tab(icon: Icon(Icons.nfc), text: 'RFID'),
          Tab(icon: Icon(Icons.usb), text: 'HID Scanner'),
          Tab(icon: Icon(Icons.qr_code), text: 'Generate'),
        ],
      ),
    );
  }

  Widget _buildQrScannerTab() {
    if (kIsWeb) {
      return WebQRScanner(onQRCodeScanned: _onQRCodeScanned);
    } else {
      return Column(
        children: [
          Expanded(child: isScanning ? _buildQRScanner() : _buildResultView()),
          _buildBottomControls(),
        ],
      );
    }
  }

  Widget _buildRfidScannerTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: RfidScanner(),
    );
  }

  Widget _buildHidScannerTab() {
    return HIDScanner(
      onScanDetected: _onQRCodeScanned,
      enabled: true,
    );
  }

  Widget _buildQrGeneratorTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: QrGenerator(),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.amber.shade600],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              _tabController.index == 0
                  ? (isScanning ? Icons.stop : Icons.qr_code_scanner)
                  : _tabController.index == 1
                      ? Icons.nfc
                      : Icons.qr_code,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _tabController.index == 0
                      ? 'QR Scanner'
                      : _tabController.index == 1
                          ? 'RFID Scanner'
                          : 'QR Generator',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  _tabController.index == 0
                      ? (isScanning
                          ? 'Position QR code within frame'
                          : 'Scan Result')
                      : _tabController.index == 1
                          ? 'Tap RFID card to scan'
                          : 'Create QR codes for students',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQRScanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.orange.shade600,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: 250,
          ),
        ),
      ),
    );
  }

  Widget _buildResultView() {
    if (lastScannedCode == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No QR code scanned',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => isScanning = true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Scan Again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (isProcessing) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
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
                    Text(
                      'Scanned Code:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lastScannedCode!,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              StudentInfoCard(qrCode: lastScannedCode!),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _performAction('entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Log Entry',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _performAction('exit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Log Exit',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  isScanning = !isScanning;
                  lastScannedCode = null;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isScanning ? Colors.red.shade600 : Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isScanning ? 'Stop Scanning' : 'Start Scanning',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !isProcessing) {
        setState(() {
          lastScannedCode = scanData.code;
          isScanning = false;
          isProcessing = true;
        });

        // Process the scanned code
        _processScannedCode(scanData.code!);
      }
    });
  }

  void _onQRCodeScanned(String qrCode) {
    if (isProcessing) return;

    setState(() {
      lastScannedCode = qrCode;
      isScanning = false;
      isProcessing = true;
    });

    // Process the scanned code
    _processScannedCode(qrCode);
  }

  Future<void> _processScannedCode(String qrCode) async {
    final provider = context.read<StudentProvider>();
    await provider.checkStudentId(qrCode);

    setState(() {
      isProcessing = false;
    });
  }

  Future<void> _performAction(String action) async {
    if (lastScannedCode == null) return;

    setState(() {
      isProcessing = true;
    });

    final provider = context.read<StudentProvider>();
    await provider.saveLogEntry(
      idNo: lastScannedCode!,
      action: action,
      timestamp: DateTime.now().toIso8601String(),
    );

    setState(() {
      isProcessing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$action logged successfully',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
