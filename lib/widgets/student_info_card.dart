import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../providers/student_provider.dart';

class StudentInfoCard extends StatefulWidget {
  final String qrCode;

  const StudentInfoCard({super.key, required this.qrCode});

  @override
  State<StudentInfoCard> createState() => _StudentInfoCardState();
}

class _StudentInfoCardState extends State<StudentInfoCard> {
  bool _isLoading = true;
  String? _studentImage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentInfo();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _error!,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
      child: Row(
        children: [
          _buildStudentImage(),
          const SizedBox(width: 16),
          Expanded(child: _buildStudentInfo()),
        ],
      ),
    );
  }

  Widget _buildStudentImage() {
    if (_studentImage != null && _studentImage!.isNotEmpty) {
      // For web-based images from PHP backend
      if (_studentImage!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _studentImage!,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }

      // For base64 encoded images
      if (_studentImage!.startsWith('data:image')) {
        try {
          final base64String = _studentImage!.split(',')[1];
          final imageBytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              imageBytes,
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          );
        } catch (e) {
          return _buildPlaceholderImage();
        }
      }
    }

    return _buildPlaceholderImage();
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.amber.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 40),
    );
  }

  Widget _buildStudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
              const SizedBox(width: 4),
              Text(
                'Student Found',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'ID Number',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 4),
        Text(
          widget.qrCode,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Future<void> _loadStudentInfo() async {
    final provider = context.read<StudentProvider>();
    final result = await provider.checkStudentId(widget.qrCode);

    setState(() {
      _isLoading = false;

      if (result.success && result.data != null) {
        _studentImage =
            result.data!['photo_location'] ?? result.data!['picture'];
      } else {
        _error = result.message ?? 'Student not found';
      }
    });
  }
}
