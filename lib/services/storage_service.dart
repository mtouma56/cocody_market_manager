import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class StorageService {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();

  // ================================================================
  // PERMISSION HANDLING
  // ================================================================

  /// Demande permission caméra
  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true; // Browser gère les permissions

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Erreur permission caméra: $e');
      return false;
    }
  }

  /// Demande permission stockage (Android seulement)
  Future<bool> _requestStoragePermission() async {
    if (kIsWeb) return true;

    try {
      final status = await Permission.storage.request();
      return status.isGranted;
    } catch (e) {
      print('❌ Erreur permission stockage: $e');
      return true; // iOS gère automatiquement
    }
  }

  // ================================================================
  // FILE UPLOAD METHODS
  // ================================================================

  /// Upload a file to business documents bucket
  Future<Map<String, dynamic>?> uploadBusinessDocument({
    required String entityType,
    required String entityId,
    required XFile file,
    required String documentType,
    String? title,
    String? description,
  }) async {
    try {
      // Read file bytes
      final bytes = await file.readAsBytes();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$entityType/$entityId/$fileName';

      // Upload to Supabase Storage
      final uploadResult = await _supabase.storage
          .from('business-documents')
          .uploadBinary(filePath, bytes);

      if (uploadResult.isEmpty) {
        throw Exception('Upload failed - no path returned');
      }

      // Save document metadata to database
      final attachmentData = {
        'entity_type': entityType,
        'entity_id': entityId,
        'file_name': file.name,
        'file_path': filePath,
        'file_size': bytes.length,
        'mime_type': file.mimeType ?? 'application/octet-stream',
        'document_type': documentType,
        'title': title ?? file.name,
        'description': description,
        'uploaded_by': _supabase.auth.currentUser?.id,
      };

      final result = await _supabase
          .from('document_attachments')
          .insert(attachmentData)
          .select()
          .single();

      return {
        'success': true,
        'attachment': result,
        'storage_path': filePath,
      };
    } catch (e) {
      print('❌ Error uploading document: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload image to public assets bucket
  Future<Map<String, dynamic>?> uploadPublicImage({
    required XFile file,
    required String folder,
    String? customName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName =
          customName ?? '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final filePath = '$folder/$fileName';

      final uploadResult = await _supabase.storage
          .from('public-assets')
          .uploadBinary(filePath, bytes);

      if (uploadResult.isEmpty) {
        throw Exception('Upload failed - no path returned');
      }

      // Get public URL for the uploaded image
      final publicUrl =
          _supabase.storage.from('public-assets').getPublicUrl(filePath);

      return {
        'success': true,
        'storage_path': filePath,
        'public_url': publicUrl,
        'file_size': bytes.length,
      };
    } catch (e) {
      print('❌ Error uploading public image: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Upload photo de profil commerçant (méthode spécifique)
  Future<Map<String, dynamic>?> uploadMerchantProfilePhoto({
    required XFile file,
    required String merchantId,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName =
          'profile_${merchantId}_${DateTime.now().millisecondsSinceEpoch}.${_getFileExtension(file.name)}';
      final filePath = 'profiles/merchants/$fileName';

      // Upload vers bucket public-assets pour les photos de profil
      final uploadResult = await _supabase.storage
          .from('public-assets')
          .uploadBinary(filePath, bytes);

      if (uploadResult.isEmpty) {
        throw Exception('Upload failed - no path returned');
      }

      // Obtenir URL publique
      final publicUrl =
          _supabase.storage.from('public-assets').getPublicUrl(filePath);

      print('✅ Photo de profil uploadée: $publicUrl');

      return {
        'success': true,
        'storage_path': filePath,
        'public_url': publicUrl,
        'file_size': bytes.length,
      };
    } catch (e) {
      print('❌ Erreur upload photo profil: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // ================================================================
  // FILE RETRIEVAL METHODS
  // ================================================================

  /// Get document attachments for an entity
  Future<List<Map<String, dynamic>>> getEntityDocuments({
    required String entityType,
    required String entityId,
  }) async {
    try {
      final result = await _supabase
          .from('document_attachments')
          .select('*')
          .eq('entity_type', entityType)
          .eq('entity_id', entityId)
          .order('created_at', ascending: false);

      // Generate signed URLs for each document
      final documentsWithUrls = <Map<String, dynamic>>[];

      for (final doc in result) {
        final signedUrlResult = await _supabase.storage
            .from('business-documents')
            .createSignedUrl(doc['file_path'], 3600); // 1 hour expiry

        documentsWithUrls.add({
          ...doc,
          'signed_url': signedUrlResult,
          'download_url': signedUrlResult,
        });
      }

      return documentsWithUrls;
    } catch (e) {
      print('❌ Error getting entity documents: $e');
      return [];
    }
  }

  /// Get all document attachments with pagination
  Future<List<Map<String, dynamic>>> getAllDocuments({
    int limit = 20,
    int offset = 0,
    String? documentType,
    String? entityType,
  }) async {
    try {
      var query = _supabase.from('document_attachments').select('*');

      if (documentType != null && documentType.isNotEmpty) {
        query = query.eq('document_type', documentType);
      }

      if (entityType != null && entityType.isNotEmpty) {
        query = query.eq('entity_type', entityType);
      }

      final result = await query
          .range(offset, offset + limit - 1)
          .order('created_at', ascending: false);

      // Generate signed URLs for documents
      final documentsWithUrls = <Map<String, dynamic>>[];

      for (final doc in result) {
        final signedUrlResult = await _supabase.storage
            .from('business-documents')
            .createSignedUrl(doc['file_path'], 3600);

        documentsWithUrls.add({
          ...doc,
          'signed_url': signedUrlResult,
          'download_url': signedUrlResult,
        });
      }

      return documentsWithUrls;
    } catch (e) {
      print('❌ Error getting all documents: $e');
      return [];
    }
  }

  /// Download file from storage
  Future<Uint8List?> downloadFile({
    required String bucketName,
    required String filePath,
  }) async {
    try {
      final result =
          await _supabase.storage.from(bucketName).download(filePath);

      return result;
    } catch (e) {
      print('❌ Error downloading file: $e');
      return null;
    }
  }

  // ================================================================
  // FILE DELETION METHODS
  // ================================================================

  /// Delete document attachment
  Future<bool> deleteDocument(String attachmentId) async {
    try {
      // Get document info first
      final doc = await _supabase
          .from('document_attachments')
          .select('file_path')
          .eq('id', attachmentId)
          .single();

      // Delete from storage
      await _supabase.storage
          .from('business-documents')
          .remove([doc['file_path']]);

      // Delete from database
      await _supabase
          .from('document_attachments')
          .delete()
          .eq('id', attachmentId);

      return true;
    } catch (e) {
      print('❌ Error deleting document: $e');
      return false;
    }
  }

  // ================================================================
  // IMAGE PICKER HELPERS (IMPROVED)
  // ================================================================

  /// Pick image from gallery
  Future<XFile?> pickImageFromGallery() async {
    try {
      // Demander permission stockage si nécessaire
      if (!await _requestStoragePermission()) {
        throw Exception('Permission d\'accès au stockage refusée');
      }

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        print('✅ Image sélectionnée de la galerie: ${image.name}');
      }

      return image;
    } catch (e) {
      print('❌ Erreur sélection galerie: $e');
      return null;
    }
  }

  /// Pick image from camera (FIXED)
  Future<XFile?> pickImageFromCamera() async {
    try {
      // Demander permission caméra
      if (!await _requestCameraPermission()) {
        throw Exception('Permission d\'accès à la caméra refusée');
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        print('✅ Photo prise avec la caméra: ${image.name}');
      }

      return image;
    } catch (e) {
      print('❌ Erreur caméra: $e');
      return null;
    }
  }

  /// Pick multiple files (documents)
  Future<List<XFile>> pickMultipleFiles() async {
    try {
      final files = await _picker.pickMultipleMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return files;
    } catch (e) {
      print('❌ Error picking multiple files: $e');
      return [];
    }
  }

  // ================================================================
  // UTILITY METHODS
  // ================================================================

  /// Get file size in human readable format
  String formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Get file icon based on mime type
  String getFileIcon(String? mimeType) {
    if (mimeType == null) return 'description';

    if (mimeType.startsWith('image/')) return 'image';
    if (mimeType == 'application/pdf') return 'picture_as_pdf';
    if (mimeType.contains('word')) return 'description';
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet'))
      return 'table_chart';
    if (mimeType.startsWith('text/')) return 'text_snippet';

    return 'attach_file';
  }

  /// Check if file is an image
  bool isImageFile(String? mimeType) {
    return mimeType?.startsWith('image/') ?? false;
  }

  /// Get document type color
  String getDocumentTypeColor(String documentType) {
    switch (documentType) {
      case 'contract':
        return '#2196F3'; // Blue
      case 'receipt':
        return '#4CAF50'; // Green
      case 'photo':
        return '#FF9800'; // Orange
      case 'identity':
        return '#9C27B0'; // Purple
      default:
        return '#757575'; // Grey
    }
  }

  /// Get file extension from filename
  String _getFileExtension(String filename) {
    return filename.split('.').last.toLowerCase();
  }
}
