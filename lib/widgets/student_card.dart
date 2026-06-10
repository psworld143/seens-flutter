import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

class StudentCard extends StatelessWidget {
  final dynamic student;
  final VoidCallback onDelete;

  const StudentCard({super.key, required this.student, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildStudentImage(),
            const SizedBox(width: 16),
            Expanded(child: _buildStudentInfo()),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentImage() {
    if (student.photoLocation != null && student.photoLocation!.isNotEmpty) {
      // For web-based images from PHP backend
      if (student.photoLocation!.startsWith('http')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            student.photoLocation!,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderImage();
            },
          ),
        );
      }

      // For base64 encoded images
      if (student.photoLocation!.startsWith('data:image')) {
        try {
          final base64String = student.photoLocation!.split(',')[1];
          final imageBytes = base64Decode(base64String);
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              imageBytes,
              width: 60,
              height: 60,
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
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange.shade400, Colors.amber.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 30),
    );
  }

  Widget _buildStudentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ID: ${student.idNo}',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Added: ${_formatDate(student.dateAdded)}',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onDelete,
          icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
          style: IconButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            padding: const EdgeInsets.all(8),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
