import 'package:flutter/material.dart';

class FileUtils {
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    return '${(bytes / 1073741824).toStringAsFixed(2)} GB';
  }

  static IconData getFileIcon(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4': case 'mkv': case 'avi': case 'mov': case 'webm': return Icons.video_file;
      case 'mp3': case 'aac': case 'wav': case 'flac': case 'm4a': return Icons.audio_file;
      case 'jpg': case 'jpeg': case 'png': case 'gif': case 'webp': return Icons.image;
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'xls': case 'xlsx': return Icons.table_chart;
      case 'ppt': case 'pptx': return Icons.slideshow;
      case 'zip': case 'rar': case '7z': case 'tar': return Icons.folder_zip;
      case 'apk': return Icons.android;
      case 'txt': return Icons.text_snippet;
      default: return Icons.insert_drive_file;
    }
  }

  static Color getFileColor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4': case 'mkv': case 'avi': case 'mov': return const Color(0xFF7C4DFF);
      case 'mp3': case 'aac': case 'wav': case 'flac': return const Color(0xFF00BCD4);
      case 'jpg': case 'jpeg': case 'png': case 'gif': return const Color(0xFF4CAF50);
      case 'pdf': return const Color(0xFFE53935);
      case 'doc': case 'docx': return const Color(0xFF1565C0);
      case 'xls': case 'xlsx': return const Color(0xFF2E7D32);
      case 'zip': case 'rar': return const Color(0xFFFF8F00);
      case 'apk': return const Color(0xFF43A047);
      default: return const Color(0xFF546E7A);
    }
  }
}
