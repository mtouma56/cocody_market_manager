import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/properties_service.dart';
import '../../widgets/custom_app_bar.dart';

class EditPropertyScreen extends StatefulWidget {
  final String propertyId;

  const EditPropertyScreen({super.key, required this.propertyId});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  final PropertiesService _service = PropertiesService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Map<String, dynamic>? _local;
  bool _hasActiveLease = false;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  String? _numero;
  String? _typeId;
  String? _etageId;
  String? _statut;

  List<Map<String, dynamic>> _propertyTypes = [];
  List<Map<String, dynamic>> _floors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load property types and floors
      final futures = await Future.wait([
        _service.getPropertyTypes(),
        _service.getFloors(),
      ]);

      _propertyTypes = futures[0];
      _floors = futures[1];

      // Load property details
      final propertyData = await _service.getPropertyDetails(widget.propertyId);
      final local = propertyData['local'];
      final bailActif = propertyData['bail_actif'];

      setState(() {
        _local = local;
        _hasActiveLease = bailActif != null;
        _numero = local['numero'];
        _typeId = local['type_id'];
        _etageId = local['etage_id'];
        _statut = local['statut'];
        _isLoading = false;
      });

      print('📍 Property loaded - Active lease: $_hasActiveLease');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // CRITICAL VALIDATION
    if (_hasActiveLease && _statut == 'Disponible') {
      _showError(
        'Impossible de modifier',
        'Ce local a un bail actif et ne peut pas être marqué comme disponible.\n\n'
            'Résiliez d\'abord le bail pour libérer le local.',
      );
      return;
    }

    if (!_hasActiveLease && _statut == 'Occupé') {
      _showError(
        'Impossible de modifier',
        'Ce local n\'a pas de bail actif et ne peut pas être marqué comme occupé.\n\n'
            'Créez d\'abord un bail pour ce local.',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _service.updateLocal(
        id: widget.propertyId,
        numero: _numero,
        typeId: _typeId,
        etageId: _etageId,
        statut: _statut,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Local mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      _showError('Erreur', 'Impossible de sauvegarder: $e');
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Modifier local'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_local == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Modifier local'),
        body: const Center(child: Text('Erreur de chargement')),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Modifier local $_numero',
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveProperty,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(4.w),
          children: [
            // Property overview card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aperçu du local',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2.w),
                    Row(
                      children: [
                        Icon(Icons.store, color: Colors.blue),
                        SizedBox(width: 2.w),
                        Text('Local $_numero'),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 3.w, vertical: 1.w),
                          decoration: BoxDecoration(
                            color: _getStatusColor(_statut ?? '').withAlpha(51),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _statut ?? '',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: _getStatusColor(_statut ?? ''),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 4.w),

            // Warning if active lease
            if (_hasActiveLease)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: EdgeInsets.all(3.w),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          'Ce local a un bail actif. Le statut "Occupé" est automatiquement déterminé.',
                          style: TextStyle(fontSize: 12.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: 4.w),

            // Property number
            TextFormField(
              initialValue: _numero,
              decoration: const InputDecoration(
                labelText: 'Numéro *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Numéro requis' : null,
              onSaved: (value) => _numero = value,
            ),

            SizedBox(height: 4.w),

            // Property type dropdown
            DropdownButtonFormField<String>(
              value: _typeId,
              decoration: const InputDecoration(
                labelText: 'Type de local *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.store),
              ),
              items: _propertyTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['id'],
                  child: Text('${type['nom']} - ${type['surface_m2']}m²'),
                );
              }).toList(),
              onChanged: (value) => setState(() => _typeId = value),
              validator: (value) => value == null ? 'Type requis' : null,
            ),

            SizedBox(height: 4.w),

            // Floor dropdown
            DropdownButtonFormField<String>(
              value: _etageId,
              decoration: const InputDecoration(
                labelText: 'Étage',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.layers),
              ),
              items: _floors.map((floor) {
                return DropdownMenuItem<String>(
                  value: floor['id'],
                  child: Text(floor['nom']),
                );
              }).toList(),
              onChanged: (value) => setState(() => _etageId = value),
            ),

            SizedBox(height: 4.w),

            // Status section with intelligent validation
            Text(
              'Statut du local',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2.w),

            // Status display with explanation
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _statut == 'Occupé' ? Icons.lock : Icons.lock_open,
                        color: _getStatusColor(_statut ?? ''),
                        size: 5.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        _statut ?? '',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(_statut ?? ''),
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.info_outline,
                        size: 4.w,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  SizedBox(height: 2.w),
                  Text(
                    'Le statut est automatiquement déterminé par les baux actifs',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (_hasActiveLease) ...[
                    SizedBox(height: 1.w),
                    Text(
                      '🔒 Local verrouillé par bail actif',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ] else ...[
                    SizedBox(height: 1.w),
                    Text(
                      '🔓 Local libre, statut modifiable',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 8.w),

            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveProperty,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 4.w),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: _isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 4.w,
                          height: 4.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 2.w),
                        const Text('Sauvegarde...'),
                      ],
                    )
                  : Text(
                      'Sauvegarder les modifications',
                      style: TextStyle(
                          fontSize: 14.sp, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'Occupé':
        return Colors.green;
      case 'Disponible':
        return Colors.blue;
      case 'Maintenance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
