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

  Future<void> _saveCommercant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateCommercant(
        commercantId: widget.commercant['id'],
        nom: _nomController.text.trim(),
        activite: _activiteController.text.trim(),
        contact: _contactController.text.trim(),
        email:
            _emailController.text.trim().isNotEmpty
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
                      child:
                          _photoUrl == null
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
                          onPressed: () {
                            // TODO: Upload photo
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Fonction upload photo à implémenter',
                                ),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          },
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
                onChanged:
                    (value) =>
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
                  child:
                      _isSaving
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
