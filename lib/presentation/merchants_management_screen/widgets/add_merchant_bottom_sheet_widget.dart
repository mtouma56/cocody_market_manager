import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/merchants_service.dart';

class AddMerchantBottomSheetWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onMerchantAdded;

  const AddMerchantBottomSheetWidget({
    super.key,
    this.onMerchantAdded,
  });

  @override
  State<AddMerchantBottomSheetWidget> createState() =>
      _AddMerchantBottomSheetWidgetState();
}

class _AddMerchantBottomSheetWidgetState
    extends State<AddMerchantBottomSheetWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _businessTypeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  final MerchantsService _merchantsService = MerchantsService();
  bool _isLoading = false;

  String _selectedPropertyType = 'Boutique 9m²';
  String _selectedFloor = 'Rez-de-chaussée';
  String _selectedPropertyNumber = '';

  final List<String> _propertyTypes = [
    'Boutique 9m²',
    'Boutique 4.5m²',
    'Banque',
    'Restaurant',
    'Box',
    'Étal de marché'
  ];

  final List<String> _floors = [
    'Rez-de-chaussée',
    '1er étage',
    '2ème étage',
    '3ème étage'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _businessTypeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            width: 12.w,
            height: 0.5.h,
            margin: EdgeInsets.symmetric(vertical: 2.h),
            decoration: BoxDecoration(
              color: colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Row(
              children: [
                Text(
                  'Nouveau Commerçant',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    size: 24,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color: colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader(context, 'Informations personnelles'),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom complet *',
                      hint: 'Entrez le nom du commerçant',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _businessTypeController,
                      label: 'Type d\'activité *',
                      hint: 'Ex: Vente de vêtements, Restauration...',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le type d\'activité est obligatoire';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 3.h),

                    // Contact Information Section
                    _buildSectionHeader(context, 'Informations de contact'),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _phoneController,
                      label: 'Téléphone *',
                      hint: '+225 XX XX XX XX XX',
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le numéro de téléphone est obligatoire';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _emailController,
                      label: 'Email (optionnel)',
                      hint: 'exemple@email.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Format d\'email invalide';
                          }
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _addressController,
                      label: 'Adresse (optionnelle)',
                      hint: 'Adresse du commerçant',
                      maxLines: 2,
                    ),
                    SizedBox(height: 3.h),

                    // Note: Pas d'attribution de local à la création
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            child: Text(
                              'Note: Le local sera attribué lors de la création du bail',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 3.h),

                    // Additional Notes Section
                    _buildSectionHeader(context, 'Notes additionnelles'),
                    SizedBox(height: 2.h),

                    _buildTextField(
                      controller: _notesController,
                      label: 'Notes',
                      hint: 'Informations supplémentaires...',
                      maxLines: 3,
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveMerchant,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 1.5.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        SizedBox(height: 0.5.h),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        SizedBox(height: 0.5.h),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.5.h,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveMerchant() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Préparer les données pour Supabase
        final merchantData = {
          'name': _nameController.text.trim(),
          'businessType': _businessTypeController.text.trim(),
          'phone': _phoneController.text.trim(),
          'profilePhoto':
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
        };

        // Ajouter l'email seulement s'il n'est pas vide
        final emailText = _emailController.text.trim();
        if (emailText.isNotEmpty) {
          merchantData['email'] = emailText;
        }

        // Ajouter l'adresse seulement si elle n'est pas vide
        final addressText = _addressController.text.trim();
        if (addressText.isNotEmpty) {
          merchantData['address'] = addressText;
        }

        // Créer le commerçant dans Supabase
        final result = await _merchantsService.addMerchant(merchantData);

        // Appeler le callback pour rafraîchir la liste
        widget.onMerchantAdded?.call(result);

        // Fermer la modal
        if (mounted) {
          Navigator.pop(context);

          // Afficher un message de succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Commerçant "${merchantData['name']}" créé avec succès'),
              backgroundColor: AppTheme.primaryGreen,
            ),
          );
        }
      } catch (error) {
        print('❌ ERREUR création commerçant: $error');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de la création: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}
