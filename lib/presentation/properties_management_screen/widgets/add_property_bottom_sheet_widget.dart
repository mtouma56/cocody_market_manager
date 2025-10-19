import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

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
  final _sizeController = TextEditingController();

  String _selectedFloor = 'rdc';
  String _selectedType = '9m2_shop';

  final List<Map<String, String>> _floors = [
    {'id': 'rdc', 'label': 'RDC'},
    {'id': '1er', 'label': '1er étage'},
    {'id': '2eme', 'label': '2ème étage'},
    {'id': '3eme', 'label': '3ème étage'},
  ];

  final List<Map<String, String>> _propertyTypes = [
    {'id': '9m2_shop', 'label': 'Boutique 9m²'},
    {'id': '4.5m2_shop', 'label': 'Boutique 4.5m²'},
    {'id': 'bank', 'label': 'Banque'},
    {'id': 'restaurant', 'label': 'Restaurant'},
    {'id': 'box', 'label': 'Box'},
    {'id': 'market_stall', 'label': 'Étal Marché'},
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _sizeController.dispose();
    super.dispose();
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
                  onPressed: () => Navigator.pop(context),
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Property number
                    Text(
                      'Numéro du Local',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _numberController,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    DropdownButtonFormField<String>(
                      value: _selectedFloor,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.layers),
                      ),
                      items: _floors.map((floor) {
                        return DropdownMenuItem<String>(
                          value: floor['id'],
                          child: Text(floor['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFloor = value;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Property type selection
                    Text(
                      'Type de Local',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: _propertyTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['id'],
                          child: Text(type['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedType = value;
                          });
                        }
                      },
                    ),

                    SizedBox(height: 3.h),

                    // Size
                    Text(
                      'Superficie',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    SizedBox(height: 1.h),
                    TextFormField(
                      controller: _sizeController,
                      decoration: const InputDecoration(
                        hintText: 'Ex: 9m², 4.5m²...',
                        prefixIcon: Icon(Icons.square_foot),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez saisir la superficie';
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
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveProperty,
                    child: const Text('Ajouter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveProperty() {
    if (_formKey.currentState!.validate()) {
      final newProperty = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'number': _numberController.text.trim(),
        'floor': _selectedFloor,
        'type': _selectedType,
        'size': _sizeController.text.trim(),
        'status': 'available',
        'createdAt': DateTime.now().toIso8601String(),
      };

      widget.onPropertyAdded(newProperty);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Local ${_numberController.text} ajouté avec succès'),
          backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        ),
      );
    }
  }
}
