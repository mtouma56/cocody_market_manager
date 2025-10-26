import 'package:flutter/material.dart';
import '../../services/merchants_service.dart';

class EditMerchantScreen extends StatefulWidget {
  final Map<String, dynamic> commercant;

  const EditMerchantScreen({super.key, required this.commercant});

  @override
  State<EditMerchantScreen> createState() => _EditMerchantScreenState();
}

class _EditMerchantScreenState extends State<EditMerchantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = MerchantsService();

  late TextEditingController _nomController;
  late TextEditingController _activiteController;
  late TextEditingController _contactController;
  late TextEditingController _emailController;

  bool _isSaving = false;
  bool _isUploadingPhoto = false;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();

    // Pré-remplir avec données actuelles
    _nomController = TextEditingController(
      text: widget.commercant['nom'] ?? '',
    );
    _activiteController = TextEditingController(
      text: widget.commercant['activite'] ?? '',
    );
    _contactController = TextEditingController(
      text: widget.commercant['contact'] ?? '',
    );
    _emailController = TextEditingController(
      text: widget.commercant['email'] ?? '',
    );
    _photoUrl = widget.commercant['photo_url'];
  }

  @override
  void dispose() {
    _nomController.dispose();
    _activiteController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _showPhotoUploadOptions() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Changer la photo de profil',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPhotoOption(
                  icon: Icons.photo_library,
                  label: 'Galerie',
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFromGallery();
                  },
                ),
                _buildPhotoOption(
                  icon: Icons.camera_alt,
                  label: 'Caméra',
                  onTap: () {
                    Navigator.pop(context);
                    _uploadFromCamera();
                  },
                ),
                if (_photoUrl != null)
                  _buildPhotoOption(
                    icon: Icons.delete,
                    label: 'Supprimer',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _removePhoto();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? Colors.blue).withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 32,
              color: color ?? Colors.blue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color ?? Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadFromGallery() async {
    setState(() => _isUploadingPhoto = true);

    try {
      final result =
          await _service.pickAndUploadFromGallery(widget.commercant['id']);

      if (result != null && result['success'] == true) {
        setState(() {
          _photoUrl = result['photo_url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(result?['error'] ?? 'Erreur lors de l\'upload');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _uploadFromCamera() async {
    setState(() => _isUploadingPhoto = true);

    try {
      final result =
          await _service.pickAndUploadFromCamera(widget.commercant['id']);

      if (result != null && result['success'] == true) {
        setState(() {
          _photoUrl = result['photo_url'];
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Photo prise et mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showError(result?['error'] ?? 'Erreur lors de la prise de photo');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isUploadingPhoto = false);
    }
  }

  void _removePhoto() {
    setState(() {
      _photoUrl = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Photo supprimée (sera appliquée lors de la sauvegarde)'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _saveCommercant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateCommercant(
        commercantId: widget.commercant['id'],
        nom: _nomController.text.trim(),
        activite: _activiteController.text.trim(),
        contact: _contactController.text.trim(),
        email: _emailController.text.trim().isNotEmpty
            ? _emailController.text.trim()
            : null,
        photoUrl: _photoUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Commerçant modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier le commerçant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                      child: _photoUrl == null
                          ? Text(
                              _nomController.text.isNotEmpty
                                  ? _nomController.text[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            )
                          : null,
                    ),
                    if (_isUploadingPhoto)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(128),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                          padding: EdgeInsets.zero,
                          onPressed: _isUploadingPhoto
                              ? null
                              : _showPhotoUploadOptions,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Nom complet
              const Text(
                'Nom complet *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Siaka Berté',
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Nom requis';
                  if (value!.length < 3)
                    return 'Nom trop court (min 3 caractères)';
                  return null;
                },
                onChanged: (value) =>
                    setState(() {}), // Refresh pour mettre à jour l'avatar
              ),

              const SizedBox(height: 16),

              // Activité
              const Text(
                'Activité *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _activiteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: Quincaillerie',
                  prefixIcon: Icon(Icons.work),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Activité requise';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Contact téléphone
              const Text(
                'Téléphone *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contactController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: +225 07 01 23 56',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Téléphone requis';
                  if (value!.length < 8) return 'Numéro invalide';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Email (optionnel)
              const Text(
                'Email (optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ex: siaka.berte@email.ci',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) return 'Email invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Bouton enregistrer
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCommercant,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Enregistrement...'),
                          ],
                        )
                      : const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
