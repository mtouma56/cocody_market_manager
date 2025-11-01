import 'package:flutter/material.dart';

import '../../services/storage_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_bottom_bar.dart';
import '../../widgets/unified_drawer.dart';
import '../../routes/app_routes.dart';
import './widgets/document_card_widget.dart';
import './widgets/document_filter_widget.dart';
import './widgets/upload_dialog_widget.dart';

class DocumentsScreen extends StatefulWidget {
  final String? entityType;
  final String? entityId;
  final String? entityName;

  const DocumentsScreen({
    Key? key,
    this.entityType,
    this.entityId,
    this.entityName,
  }) : super(key: key);

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final _storageService = StorageService();

  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  String _selectedEntityFilter = 'all';

  final List<String> _documentTypes = [
    'all',
    'contract',
    'receipt',
    'photo',
    'identity',
    'other'
  ];

  final List<String> _entityTypes = [
    'all',
    'commercant',
    'local',
    'bail',
    'paiement'
  ];

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);

    try {
      List<Map<String, dynamic>> documents;

      if (widget.entityType != null && widget.entityId != null) {
        // Load documents for specific entity
        documents = await _storageService.getEntityDocuments(
          entityType: widget.entityType!,
          entityId: widget.entityId!,
        );
      } else {
        // Load all documents with filters
        documents = await _storageService.getAllDocuments(
          documentType: _selectedFilter == 'all' ? null : _selectedFilter,
          entityType:
              _selectedEntityFilter == 'all' ? null : _selectedEntityFilter,
          limit: 50,
        );
      }

      setState(() {
        _documents = documents;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading documents: $e');
      setState(() => _isLoading = false);
      _showErrorSnackBar('Erreur lors du chargement des documents');
    }
  }

  Future<void> _showUploadDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UploadDialogWidget(
        entityType: widget.entityType,
        entityId: widget.entityId,
        entityName: widget.entityName,
      ),
    );

    if (result != null && result['success'] == true) {
      _showSuccessSnackBar('Document uploadé avec succès');
      _loadDocuments();
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirmed = await _showDeleteConfirmation();
    if (!confirmed) return;

    final success = await _storageService.deleteDocument(documentId);

    if (success) {
      _showSuccessSnackBar('Document supprimé avec succès');
      _loadDocuments();
    } else {
      _showErrorSnackBar('Erreur lors de la suppression');
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmer la suppression'),
            content:
                const Text('Êtes-vous sûr de vouloir supprimer ce document ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  int _getBottomBarIndex() {
    // Documents is not in the bottom navigation bar, so return -1
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    final bool isEntitySpecific =
        widget.entityType != null && widget.entityId != null;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.entityName != null
            ? 'Documents - ${widget.entityName}'
            : 'Tous les documents',
        // For entity-specific documents, show back button. For general documents, show drawer
        automaticallyImplyLeading: isEntitySpecific,
        leading: isEntitySpecific
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDocuments,
          ),
        ],
      ),
      // Only show drawer for general documents view, not for entity-specific
      drawer: !isEntitySpecific
          ? UnifiedDrawer(currentRoute: AppRoutes.documentsScreen)
          : null,
      body: Column(
        children: [
          // Filters section (only show for all documents view)
          if (widget.entityType == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DocumentFilterWidget(
                    label: 'Type de document',
                    value: _selectedFilter,
                    items: _documentTypes,
                    onChanged: (value) {
                      setState(() => _selectedFilter = value);
                      _loadDocuments();
                    },
                  ),
                  const SizedBox(height: 12),
                  DocumentFilterWidget(
                    label: 'Entité',
                    value: _selectedEntityFilter,
                    items: _entityTypes,
                    onChanged: (value) {
                      setState(() => _selectedEntityFilter = value);
                      _loadDocuments();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],

          // Documents list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _documents.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadDocuments,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _documents.length,
                          itemBuilder: (context, index) {
                            final document = _documents[index];
                            return DocumentCardWidget(
                              document: document,
                              onDelete: () => _deleteDocument(document['id']),
                              storageService: _storageService,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      // Only show bottom navigation for general documents view, not for entity-specific
      bottomNavigationBar: !isEntitySpecific
          ? CustomBottomBar(currentIndex: _getBottomBarIndex())
          : null,
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadDialog,
        child: const Icon(Icons.add),
        tooltip: 'Ajouter un document',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun document',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Appuyez sur + pour ajouter des documents',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
