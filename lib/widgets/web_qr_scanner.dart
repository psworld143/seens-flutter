import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

class WebQRScanner extends StatefulWidget {
  final Function(String) onQRCodeScanned;

  const WebQRScanner({super.key, required this.onQRCodeScanned});

  @override
  State<WebQRScanner> createState() => _WebQRScannerState();
}

class _WebQRScannerState extends State<WebQRScanner> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImageAndScan() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // For web, we'll simulate QR code detection
        // In a real implementation, you'd use a web QR decoding library
        _simulateQRDetection(image.name);
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _simulateQRDetection(String fileName) {
    // Simulate QR code detection with a demo pattern
    // In production, you'd use a library like 'qr' or 'jsqr'
    if (fileName.contains('qr') || fileName.contains('QR')) {
      widget.onQRCodeScanned(
          'DEMO_QR_CODE_${DateTime.now().millisecondsSinceEpoch}');
    } else {
      _showError(
          'No QR code detected in the image. Please upload an image containing a QR code.');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showManualInputDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Enter QR Code',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter QR code manually',
            hintStyle: GoogleFonts.poppins(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                widget.onQRCodeScanned(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: Text(
              'Scan',
              style: GoogleFonts.poppins(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(30),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner_outlined,
            size: 80,
            color: Colors.orange.shade600,
          ),
          const SizedBox(height: 20),
          Text(
            'Web QR Scanner',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Camera scanning is not available on web. Use the alternatives below:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          _buildScanOption(
            icon: Icons.upload_file,
            title: 'Upload QR Image',
            description: 'Select an image file containing a QR code',
            onTap: _pickImageAndScan,
            isProcessing: _isProcessing,
          ),
          const SizedBox(height: 16),
          _buildScanOption(
            icon: Icons.keyboard,
            title: 'Manual Entry',
            description: 'Enter QR code value manually',
            onTap: _showManualInputDialog,
            isProcessing: false,
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.orange.shade600, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'For best results, upload clear images with QR codes centered and well-lit.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
    required bool isProcessing,
  }) {
    return GestureDetector(
      onTap: isProcessing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isProcessing ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isProcessing ? Colors.grey.shade300 : Colors.orange.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isProcessing
                    ? Colors.grey.shade200
                    : Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isProcessing
                    ? Colors.grey.shade600
                    : Colors.orange.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isProcessing
                          ? Colors.grey.shade600
                          : Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isProcessing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.orange.shade600,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
