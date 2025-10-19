import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/properties_service.dart';

class AddPropertyBottomSheetWidget extends StatefulWidget {
  final Function(Map<String, dynamic>) onPropertyAdded;

  const AddPropertyBottomSheetWidget({
    super.key,
    required this.onPropertyAdded,
  });

  @override
  State<AddPropertyBottomSheetWidget> createState() =>
      _AddPropertyBottomSheetWidgetState();
}

class _AddPropertyBottomSheetWidgetState
    extends State<AddPropertyBottomSheetWidget> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();

  String _selectedFloor = 'rdc';
  String _selectedType = '9m2_shop';
  bool _isLoading = false;

  // Dynamic data from Supabase
  List<Map<String, dynamic>> _floors = [];
  List<Map<String, dynamic>> _propertyTypes = [];
  bool _isDataLoading = true;

  final PropertiesService _propertiesService = PropertiesService();

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  /// Charge les données nécessaires pour le formulaire
  Future<void> _loadFormData() async {
    try {
      final floors = await _propertiesService.getFloors();
      final propertyTypes = await _propertiesService.getPropertyTypes();

      setState(() {
        _floors = floors;
        _propertyTypes = propertyTypes;
        _isDataLoading = false;

        // Set defaults if data available
        if (_floors.isNotEmpty) {
          _selectedFloor = _floors.first['id'];
        }
        if (_propertyTypes.isNotEmpty) {
          _selectedType = _propertyTypes.first['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isDataLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur de chargement: ${e.toString()}'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85.h,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ajouter un Local',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Divider(
            color:
                AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
            height: 1,
          ),

          // Form content
          Expanded(
            child: _isDataLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement des données...'),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Property number
                          Text(
                            'Numéro du Local',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 1.h),
                          TextFormField(
                            controller: _numberController,
                            enabled: !_isLoading,
                            decoration: const InputDecoration(
                              hintText: 'Ex: A-101, B-205...',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez saisir le numéro du local';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 3.h),

                          // Floor selection
                          Text(
                            'Étage',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 1.h),
                          DropdownButtonFormField<String>(
                            value: _floors.isNotEmpty ? _selectedFloor : null,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.layers),
                            ),
                            items: _floors.map((floor) {
                              return DropdownMenuItem<String>(
                                value: floor['id'],
                                child: Text(floor['nom'] ?? 'Étage'),
                              );
                            }).toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedFloor = value;
                                      });
                                    }
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un étage';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 3.h),

                          // Property type selection
                          Text(
                            'Type de Local',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: 1.h),
                          DropdownButtonFormField<String>(
                            value: _propertyTypes.isNotEmpty
                                ? _selectedType
                                : null,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.business),
                            ),
                            items: _propertyTypes.map((type) {
                              return DropdownMenuItem<String>(
                                value: type['id'],
                                child: Text(type['nom'] ?? 'Type'),
                              );
                            }).toList(),
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    if (value != null) {
                                      setState(() {
                                        _selectedType = value;
                                      });
                                    }
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez sélectionner un type';
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 4.h),
                        ],
                      ),
                    ),
                  ),
          ),

          // Action buttons
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: AppTheme.lightTheme.colorScheme.outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isLoading || _isDataLoading ? null : _createLocal,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Crée le local dans Supabase
  Future<void> _createLocal() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Crée dans Supabase
      final createdLocal = await _propertiesService.createLocal(
        numero: _numberController.text.trim(),
        typeId: _selectedType,
        etageId: _selectedFloor,
        statut: 'Disponible',
      );

      if (mounted) {
        // Transforme la réponse Supabase en format UI
        final uiProperty = _transformSupabaseToUI(createdLocal);

        // Notify parent
        widget.onPropertyAdded(uiProperty);

        // Close dialog
        Navigator.pop(context);

        // Affiche succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Local ${_numberController.text} créé avec succès'),
            backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Affiche erreur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      print('❌ Erreur création local: $e');
    }
  }

  /// Transforme la réponse Supabase en format UI
  Map<String, dynamic> _transformSupabaseToUI(
      Map<String, dynamic> supabaseLocal) {
    return {
      'id': supabaseLocal['id'],
      'number': supabaseLocal['numero'],
      'floor': _getFloorCode(supabaseLocal['etages']?['ordre'] ?? 0),
      'type': _getPropertyTypeCode(supabaseLocal['types_locaux']?['nom'] ?? ''),
      'size': '${supabaseLocal['types_locaux']?['surface_m2'] ?? 0}m²',
      'status': _getStatusCode(supabaseLocal['statut'] ?? 'Disponible'),
    };
  }

  /// Convertit l'ordre d'étage en code court
  String _getFloorCode(int ordre) {
    switch (ordre) {
      case 0:
        return 'rdc';
      case 1:
        return '1er';
      case 2:
        return '2eme';
      case 3:
        return '3eme';
      default:
        return 'rdc';
    }
  }

  /// Convertit le nom du type en code
  String _getPropertyTypeCode(String typeName) {
    switch (typeName) {
      case 'Boutique 9m²':
        return '9m2_shop';
      case 'Boutique 4.5m²':
        return '4.5m2_shop';
      case 'Restaurant':
        return 'restaurant';
      case 'Banque':
        return 'bank';
      case 'Box':
        return 'box';
      case 'Étal':
        return 'market_stall';
      default:
        return '9m2_shop';
    }
  }

  /// Convertit le statut Supabase en code
  String _getStatusCode(String supabaseStatus) {
    switch (supabaseStatus) {
      case 'Occupé':
        return 'occupied';
      case 'Disponible':
        return 'available';
      case 'Maintenance':
        return 'maintenance';
      default:
        return 'available';
    }
  }
}
