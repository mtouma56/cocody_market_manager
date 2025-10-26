import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentCardWidget extends StatelessWidget {
  final Map<String, dynamic> document;
  final VoidCallback onDelete;
  final StorageService storageService;

  const DocumentCardWidget({
    Key? key,
    required this.document,
    required this.onDelete,
    required this.storageService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isImage = storageService.isImageFile(document['mime_type']);
    final fileSize = storageService.formatFileSize(document['file_size'] ?? 0);
    final documentType = document['document_type'] ?? 'other';
    final typeColor = Color(int.parse(storageService
        .getDocumentTypeColor(documentType)
        .replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and actions
            Row(
              children: [
                // Document type indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: typeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),

                // Title and metadata
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['title'] ??
                            document['file_name'] ??
                            'Document',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: typeColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getDocumentTypeLabel(documentType),
                            style: TextStyle(
                              fontSize: 12,
                              color: typeColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.folder_outlined,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getEntityTypeLabel(document['entity_type']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions menu
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                  onSelected: (value) {
                    switch (value) {
                      case 'download':
                        _downloadDocument(context);
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'download',
                      child: Row(
                        children: [
                          Icon(Icons.download, size: 18),
                          SizedBox(width: 8),
                          Text('Télécharger'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Preview section
            if (isImage && document['signed_url'] != null) ...[
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: document['signed_url'],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, size: 48),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ] else ...[
              // File icon for non-images
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getFileIcon(document['mime_type']),
                        size: 32,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        document['file_name'] ?? 'Document',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Description if available
            if (document['description'] != null &&
                document['description'].toString().isNotEmpty) ...[
              Text(
                document['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],

            // Footer with metadata
            Row(
              children: [
                Icon(Icons.insert_drive_file,
                    size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  fileSize,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  _formatDate(document['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Spacer(),

                // Download button
                TextButton.icon(
                  onPressed: () => _downloadDocument(context),
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Télécharger'),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _downloadDocument(BuildContext context) async {
    final signedUrl = document['signed_url'];
    if (signedUrl != null) {
      try {
        if (await canLaunchUrl(Uri.parse(signedUrl))) {
          await launchUrl(Uri.parse(signedUrl));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible d\'ouvrir le document'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors du téléchargement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.description;

    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType == 'application/pdf') return Icons.picture_as_pdf;
    if (mimeType.contains('word')) return Icons.description;
    if (mimeType.contains('excel') || mimeType.contains('spreadsheet'))
      return Icons.table_chart;
    if (mimeType.startsWith('text/')) return Icons.text_snippet;

    return Icons.attach_file;
  }

  String _getDocumentTypeLabel(String documentType) {
    switch (documentType) {
      case 'contract':
        return 'Contrat';
      case 'receipt':
        return 'Reçu';
      case 'photo':
        return 'Photo';
      case 'identity':
        return 'Identité';
      case 'other':
        return 'Autre';
      default:
        return 'Document';
    }
  }

  String _getEntityTypeLabel(String? entityType) {
    switch (entityType) {
      case 'commercant':
        return 'Commerçant';
      case 'local':
        return 'Local';
      case 'bail':
        return 'Bail';
      case 'paiement':
        return 'Paiement';
      default:
        return 'Général';
    }
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return '';

    try {
      final date = DateTime.parse(dateTime.toString());
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return dateTime.toString();
    }
  }
}
