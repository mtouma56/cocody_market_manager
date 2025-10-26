import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage_service.dart';

class UploadDialogWidget extends StatefulWidget {
  final String? entityType;
  final String? entityId;
  final String? entityName;

  const UploadDialogWidget({
    Key? key,
    this.entityType,
    this.entityId,
    this.entityName,
  }) : super(key: key);

  @override
  State<UploadDialogWidget> createState() => _UploadDialogWidgetState();
}

class _UploadDialogWidgetState extends State<UploadDialogWidget> {
  final _storageService = StorageService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedDocumentType = 'other';
  String _selectedEntityType = 'commercant';
  bool _isUploading = false;
  XFile? _selectedFile;
  bool _isSaving = false;

  final List<Map<String, String>> _documentTypes = [
    {'value': 'contract', 'label': 'Contrat'},
    {'value': 'receipt', 'label': 'Reçu'},
    {'value': 'photo', 'label': 'Photo'},
    {'value': 'identity', 'label': 'Pièce d\'identité'},
    {'value': 'other', 'label': 'Autre'},
  ];

  final List<Map<String, String>> _entityTypes = [
    {'value': 'commercant', 'label': 'Commerçant'},
    {'value': 'local', 'label': 'Local'},
    {'value': 'bail', 'label': 'Bail'},
    {'value': 'paiement', 'label': 'Paiement'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.entityType != null) {
      _selectedEntityType = widget.entityType!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.cloud_upload, color: Colors.blue),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ajouter un document',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // File selection
            _buildFileSelectionSection(),

            const SizedBox(height: 20),

            // Document details form
            _buildDocumentDetailsForm(),

            const SizedBox(height: 24),

            // Action buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSelectionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
            color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          if (_selectedFile == null) ...[
            Icon(
              Icons.cloud_upload_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Sélectionnez un fichier',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF, Images, Documents Word/Excel\nTaille max: 20MB',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilePickerButton(
                  icon: Icons.folder,
                  label: 'Fichiers',
                  onPressed: _pickFile,
                ),
                _buildFilePickerButton(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onPressed: _pickImageFromGallery,
                ),
                _buildFilePickerButton(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onPressed: _pickImageFromCamera,
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  _storageService.isImageFile(_selectedFile!.mimeType)
                      ? Icons.image
                      : _getFileIcon(_selectedFile!.mimeType),
                  size: 32,
                  color: Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _selectedFile!.mimeType ?? 'Type inconnu',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _selectedFile = null),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilePickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
          ),
          child: Icon(icon),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDocumentDetailsForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title field
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titre du document',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.title),
          ),
        ),

        const SizedBox(height: 16),

        // Document type selection
        DropdownButtonFormField<String>(
          value: _selectedDocumentType,
          decoration: const InputDecoration(
            labelText: 'Type de document',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          items: _documentTypes.map((type) {
            return DropdownMenuItem(
              value: type['value'],
              child: Text(type['label']!),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedDocumentType = value!);
          },
        ),

        const SizedBox(height: 16),

        // Entity type selection (only if not specified)
        if (widget.entityType == null) ...[
          DropdownButtonFormField<String>(
            value: _selectedEntityType,
            decoration: const InputDecoration(
              labelText: 'Associé à',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            items: _entityTypes.map((type) {
              return DropdownMenuItem(
                value: type['value'],
                child: Text(type['label']!),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedEntityType = value!);
            },
          ),
          const SizedBox(height: 16),
        ],

        // Description field
        TextField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Description (optionnelle)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed:
              _isUploading || _selectedFile == null ? null : _uploadDocument,
          child: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Uploader'),
        ),
      ],
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'doc',
          'docx',
          'xls',
          'xlsx',
          'txt',
          'jpg',
          'jpeg',
          'png',
          'webp'
        ],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _selectedFile = XFile(
            file.path!,
            name: file.name,
            mimeType: _getMimeType(file.extension),
          );
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.split('.').first;
          }
        });
      }
    } catch (e) {
      _showError('Erreur lors de la sélection du fichier');
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      setState(() => _isSaving = true);

      final file = await _storageService.pickImageFromGallery();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          if (_titleController.text.isEmpty) {
            _titleController.text = file.name.split('.').first;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image sélectionnée'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucune image sélectionnée'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur galerie: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      setState(() => _isSaving = true);

      final file = await _storageService.pickImageFromCamera();
      if (file != null) {
        setState(() {
          _selectedFile = file;
          if (_titleController.text.isEmpty) {
            _titleController.text =
                'Photo_${DateTime.now().millisecondsSinceEpoch}';
          }
        });

        // Petite indication de succès
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo prise avec succès'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucune photo prise'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showError('Erreur caméra: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final result = await _storageService.uploadBusinessDocument(
        entityType: widget.entityType ?? _selectedEntityType,
        entityId: widget.entityId ?? 'general',
        file: _selectedFile!,
        documentType: _selectedDocumentType,
        title: _titleController.text.isNotEmpty
            ? _titleController.text
            : _selectedFile!.name,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      if (result != null && result['success'] == true) {
        Navigator.pop(context, result);
      } else {
        _showError(result?['error'] ?? 'Erreur lors de l\'upload');
      }
    } catch (e) {
      _showError('Erreur lors de l\'upload: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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

  String? _getMimeType(String? extension) {
    if (extension == null) return null;

    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}
