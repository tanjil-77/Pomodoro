import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://smmcgjsnyhulutfrdsfg.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNtbWNnanNueWh1bHV0ZnJkc2ZnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQzMTk0MjAsImV4cCI6MjA3OTg5NTQyMH0.GNKSVeKSfJWsJlgsYgLdAYzEdkJUQuzJBYGSMWgjPFM';
  static const String bucketName = 'pdf-store';

  static SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  // Sanitize filename to remove special characters and Bengali characters
  static String _sanitizeFileName(String fileName) {
    // Remove file extension
    final nameWithoutExt = fileName.replaceAll('.pdf', '');

    // Replace non-ASCII and special characters with underscores
    final sanitized = nameWithoutExt
        .replaceAll(RegExp(r'[^\w\s-]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .trim();

    // Limit length to 50 characters
    final truncated = sanitized.length > 50
        ? sanitized.substring(0, 50)
        : sanitized;

    return '${truncated.isEmpty ? 'book' : truncated}.pdf';
  }

  // Upload PDF to Supabase Storage
  static Future<String> uploadPDF(File file, String fileName) async {
    try {
      // Generate unique filename with timestamp and sanitized name
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sanitizedName = _sanitizeFileName(fileName);
      final uniqueFileName = '${timestamp}_$sanitizedName';

      // Upload file to Supabase Storage
      await client.storage.from(bucketName).upload(uniqueFileName, file);

      // Get public URL
      final String publicUrl = client.storage
          .from(bucketName)
          .getPublicUrl(uniqueFileName);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  // Save book metadata to Supabase Database
  static Future<void> saveBookMetadata({
    required String title,
    required String author,
    required String pdfUrl,
    required String fileName,
  }) async {
    try {
      await client.from('books').insert({
        'title': title,
        'author': author,
        'pdf_url': pdfUrl,
        'file_name': fileName,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to save book metadata: $e');
    }
  }

  // Get all books from Supabase Database
  static Future<List<Map<String, dynamic>>> getAllBooks() async {
    try {
      final response = await client
          .from('books')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  // Delete book from Supabase
  static Future<void> deleteBook(int bookId, String pdfUrl) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(pdfUrl);
      final fileName = uri.pathSegments.last;

      // Delete from storage
      await client.storage.from(bucketName).remove([fileName]);

      // Delete from database
      await client.from('books').delete().eq('id', bookId);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Download PDF for offline reading
  static Future<File?> downloadPDF(String pdfUrl, String fileName) async {
    try {
      final response = await client.storage.from(bucketName).download(fileName);

      // Save to temporary directory
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(response);

      return file;
    } catch (e) {
      throw Exception('Failed to download PDF: $e');
    }
  }
}
