import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:intl/intl.dart';

import '../../services/bail_validation_service.dart';
import '../../services/leases_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/validated_text_form_field.dart';

class AddLeaseFormScreen extends StatefulWidget {
  const AddLeaseFormScreen({super.key});

  @override
  State<AddLeaseFormScreen> createState() => _AddLeaseFormScreenState();
}

class _AddLeaseFormScreenState extends State<AddLeaseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _leasesService = LeasesService();
  final _validationService = BailValidationService();

  // Form controllers and variables
  String? _selectedPropertyId;
  String? _selectedMerchantId;
  DateTime? _dateDebut;
  DateTime? _dateFin;
  final _rentAmountController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  String _contractNumber = '';
  String _depositType = 'caution'; // 'caution' or 'pas_de_porte'

  // ADDED variables for search functionality
  final _localSearchController = TextEditingController();
  Map<String, dynamic>? _selectedLocalData;
  // NEW: Added merchant search variables
  final _commercantSearchController = TextEditingController();
  Map<String, dynamic>? _selectedCommercantData;

  // Data lists
  List<Map<String, dynamic>> _availableProperties = [];
  List<Map<String, dynamic>> _activeMerchants = [];

  // State management
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _rentAmountController.dispose();
    _depositAmountController.dispose();
    _localSearchController.dispose();
    _commercantSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final futures = await Future.wait([
        _leasesService.getAvailableProperties(),
        _leasesService.getActiveMerchants(),
        _leasesService.generateContractNumber(),
      ]);

      if (mounted) {
        setState(() {
          _availableProperties = futures[0] as List<Map<String, dynamic>>;
          _activeMerchants = futures[1] as List<Map<String, dynamic>>;
          _contractNumber = futures[2] as String;
          _isLoading = false;
        });

        print(
          '✅ Données chargées: ${_availableProperties.length} locaux, ${_activeMerchants.length} commerçants',
        );
      }
    } catch (error) {
      print('❌ Erreur chargement formulaire: $error');
      if (mounted) {
        setState(() {
          _error = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDateDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 3650)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isDateDebut) {
          _dateDebut = picked;
          if (_dateFin != null && _dateFin!.isBefore(_dateDebut!)) {
            _dateFin = null;
          }
        } else {
          if (_dateDebut != null && picked.isBefore(_dateDebut!)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Date fin doit être après date début')),
            );
          } else {
            _dateFin = picked;
          }
        }
      });
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedPropertyId == null) {
      _showError('Veuillez sélectionner un local');
      return false;
    }

    if (_selectedMerchantId == null) {
      _showError('Veuillez sélectionner un commerçant');
      return false;
    }

    if (_dateDebut == null || _dateFin == null) {
      _showError('Veuillez sélectionner les dates de début et de fin');
      return false;
    }

    if (_dateFin!.isBefore(_dateDebut!)) {
      _showError('La date de fin doit être après la date de début');
      return false;
    }

    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _creerBail() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    // ═══════════════════════════════════════════════════════
    // VALIDATION CRITIQUE : Vérifier disponibilité local
    // ═══════════════════════════════════════════════════════

    final validation =
        await _validationService.verifierLocalDisponible(_selectedPropertyId!);

    if (!validation.isValid) {
      final bail = validation.bailExistant;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.block, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Local déjà occupé',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Impossible de créer ce bail',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Ce local a déjà un bail actif. Un local ne peut avoir qu\'un seul bail actif à la fois.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                if (bail != null) ...[
                  SizedBox(height: 20),
                  Text(
                    'Bail existant :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.receipt,
                    'Contrat',
                    bail['numero_contrat'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.person,
                    'Commerçant',
                    bail['commercants']?['nom'] ?? 'N/A',
                  ),
                  _buildInfoRow(
                    Icons.payments,
                    'Loyer',
                    '${bail['montant_loyer']} FCFA/mois',
                  ),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Résiliez d\'abord le bail existant pour libérer ce local.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Compris'),
            ),
          ],
        ),
      );

      return; // ARRÊT - Ne crée PAS le bail
    }

    // ═══════════════════════════════════════════════════════
    // Si validation OK, créer le bail
    // ═══════════════════════════════════════════════════════

    // Parse amounts from text controllers
    final rentAmount =
        double.parse(_rentAmountController.text.replaceAll(' ', ''));
    final depositAmount = _depositAmountController.text.isEmpty
        ? 0.0
        : double.parse(_depositAmountController.text.replaceAll(' ', ''));

    try {
      // FIX: Call createLease with named parameters instead of Map
      await _leasesService.createLease(
        contractNumber: _contractNumber,
        propertyId: _selectedPropertyId!,
        merchantId: _selectedMerchantId!,
        startDate: _dateDebut!,
        endDate: _dateFin!,
        monthlyRent: rentAmount,
        montantCaution: _depositType == 'caution' ? depositAmount : null,
        montantPasDePorte:
            _depositType == 'pas_de_porte' ? depositAmount : null,
      );

      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bail créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Erreur'),
          content: Text('Impossible de créer le bail: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          SizedBox(width: 8),
          Text(
            '$label : ',
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _getPropertyDisplayText(Map<String, dynamic> property) {
    final numero = property['numero'] ?? 'N/A';
    final typeName = property['types_locaux']?['nom'] ?? 'Type inconnu';
    final floorName = property['etages']?['nom'] ?? 'Étage inconnu';
    final surface = property['types_locaux']?['surface_m2'] ?? 0;

    return '$numero - $typeName ($floorName) - ${surface}m²';
  }

  String _getMerchantDisplayText(Map<String, dynamic> merchant) {
    final name = merchant['nom'] ?? 'N/A';
    final business = merchant['activite'] ?? '';

    return business.isNotEmpty ? '$name - $business' : name;
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Nouveau Bail',
        variant: CustomAppBarVariant.standard,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement du formulaire...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Nouveau Bail',
        variant: CustomAppBarVariant.standard,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 64),
              SizedBox(height: 2.h),
              Text(
                'Erreur de chargement',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              SizedBox(height: 1.h),
              Text(
                _error ?? 'Une erreur est survenue',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: _loadFormData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractNumberCard() {
    return Card(
      margin: EdgeInsets.all(4.w),
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(Icons.tag, color: Colors.blue.shade700, size: 28),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro de contrat',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    _contractNumber,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _contractNumber));
                HapticFeedback.lightImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Numéro copié'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              icon: Icon(Icons.copy, color: Colors.blue.shade700),
              tooltip: 'Copier le numéro',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String? title, Widget child) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 1.h),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildDepositSection() {
    return Column(
      children: [
        // Type de dépôt (Radio buttons)
        _buildFormSection(
          'Type de dépôt',
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text(
                    'Caution (remboursable)',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Montant remboursable en fin de bail',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: 'caution',
                  groupValue: _depositType,
                  onChanged: (value) {
                    setState(() => _depositType = value!);
                    HapticFeedback.lightImpact();
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
                Divider(height: 1, color: Colors.grey[200]),
                RadioListTile<String>(
                  title: Text(
                    'Pas de porte (non-remboursable)',
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                  subtitle: Text(
                    'Montant versé pour obtenir le local',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                  value: 'pas_de_porte',
                  groupValue: _depositType,
                  onChanged: (value) {
                    setState(() => _depositType = value!);
                    HapticFeedback.lightImpact();
                  },
                  activeColor: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 1.h),

        // Montant du dépôt
        _buildFormSection(
          null,
          ValidatedTextFormField(
            controller: _depositAmountController,
            label:
                'Montant du ${_depositType == 'caution' ? 'caution' : 'pas de porte'} (FCFA)',
            hintText: 'Ex: 50000 (optionnel)',
            prefixIcon: _depositType == 'caution'
                ? Icons.shield
                : Icons.store_mall_directory,
            suffixText: 'FCFA',
            helperText: _depositType == 'caution'
                ? 'Montant remboursable à la fin du bail'
                : 'Montant non-remboursable pour l\'obtention du local',
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              TextInputFormatter.withFunction((oldValue, newValue) {
                final text = newValue.text;
                if (text.isEmpty) return newValue;

                final number = int.tryParse(text);
                if (number == null) return oldValue;

                final formatted = number.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (match) => '${match[1]} ',
                    );

                return TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              }),
            ],
            validator: (value) {
              if (value.isEmpty) {
                return null;
              }

              final cleanValue = value.replaceAll(' ', '');
              final amount = double.tryParse(cleanValue);
              if (amount == null) {
                return 'Montant invalide';
              }

              if (amount <= 0) {
                return 'Le montant doit être positif';
              }

              return null;
            },
            dynamicHintBuilder: (value) {
              if (value.trim().isEmpty) {
                return _depositType == 'caution'
                    ? 'Facultatif mais conseillé pour sécuriser les impayés'
                    : 'Saisissez 0 si aucun pas de porte n\'est requis';
              }
              final cleanValue = value.replaceAll(' ', '');
              final amount = double.tryParse(cleanValue);
              if (amount == null || amount <= 0) {
                return '';
              }

              if (_depositType == 'caution') {
                final trimestre = amount / 3;
                return 'Couvre environ ${_currencyFormat.format(trimestre)} par trimestre de garantie';
              }

              return 'Encaissement initial total: ${_currencyFormat.format(amount)}';
            },
          ),
        ),
      ],
    );
  }

  // NEW: Searchable local selection bottom sheet
  Widget _buildLocalSearchBottomSheet() {
    return StatefulBuilder(
      builder: (context, setBottomSheetState) {
        List<Map<String, dynamic>> filteredProperties =
            _availableProperties.where((local) {
          final query = _localSearchController.text.toLowerCase();
          if (query.isEmpty) return true;

          final numero = (local['numero'] ?? '').toString().toLowerCase();
          final type =
              (local['types_locaux']?['nom'] ?? '').toString().toLowerCase();
          final etage =
              (local['etages']?['nom'] ?? '').toString().toLowerCase();

          return numero.contains(query) ||
              type.contains(query) ||
              etage.contains(query);
        }).toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sélectionner un local',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Search field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _localSearchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (query) {
                      setBottomSheetState(() {}); // Refresh filtered list
                    },
                  ),
                ),

                SizedBox(height: 8),

                // Results counter
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredProperties.length} local(x) trouvé(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                // Property list
                Expanded(
                  child: filteredProperties.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Aucun local trouvé',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Essayez un autre terme de recherche',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredProperties.length,
                          itemBuilder: (context, index) {
                            final local = filteredProperties[index];
                            final numero = local['numero'] ?? 'N/A';
                            final type = local['types_locaux']?['nom'] ?? '';
                            final etage = local['etages']?['nom'] ?? '';
                            final surface =
                                local['types_locaux']?['surface_m2'] ?? 0;

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.store, color: Colors.blue),
                              ),
                              title: Text(
                                numero,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '$type - $etage - ${surface}m²',
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedPropertyId = local['id'];
                                  _selectedLocalData = local;
                                });
                                _localSearchController.clear();
                                Navigator.pop(context, local);
                              },
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // NEW: Searchable merchant selection bottom sheet
  Widget _buildMerchantSearchBottomSheet() {
    return StatefulBuilder(
      builder: (context, setBottomSheetState) {
        List<Map<String, dynamic>> filteredMerchants =
            _activeMerchants.where((commercant) {
          final query = _commercantSearchController.text.toLowerCase();
          if (query.isEmpty) return true;

          final nom = (commercant['nom'] ?? '').toString().toLowerCase();
          final activite =
              (commercant['activite'] ?? '').toString().toLowerCase();
          final contact =
              (commercant['contact'] ?? '').toString().toLowerCase();

          return nom.contains(query) ||
              activite.contains(query) ||
              contact.contains(query);
        }).toList();

        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Title
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Sélectionner un commerçant',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Search field
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: _commercantSearchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    onChanged: (query) {
                      setBottomSheetState(() {}); // Refresh filtered list
                    },
                  ),
                ),

                SizedBox(height: 8),

                // Results counter
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredMerchants.length} commerçant(s) trouvé(s)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),

                // Merchant list
                Expanded(
                  child: filteredMerchants.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off,
                                  size: 48, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Aucun commerçant trouvé',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Essayez un autre terme de recherche',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredMerchants.length,
                          itemBuilder: (context, index) {
                            final commercant = filteredMerchants[index];
                            final nom = commercant['nom'] ?? '';
                            final activite = commercant['activite'] ?? '';
                            final contact = commercant['contact'] ?? '';

                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: Text(
                                  nom.isNotEmpty
                                      ? nom.substring(0, 1).toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ),
                              title: Text(
                                nom,
                                style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '$activite\n$contact',
                                maxLines: 2,
                                style: GoogleFonts.inter(fontSize: 12),
                              ),
                              isThreeLine: true,
                              onTap: () {
                                setState(() {
                                  _selectedMerchantId = commercant['id'];
                                  _selectedCommercantData = commercant;
                                });
                                _commercantSearchController.clear();
                                Navigator.pop(context, commercant);
                              },
                              trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _buildLoadingState();
    if (_error != null) return _buildErrorState();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Nouveau Bail',
        variant: CustomAppBarVariant.standard,
        actions: [
          if (_isSaving)
            Center(
              child: Padding(
                padding: EdgeInsets.only(right: 4.w),
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contract number card
              _buildContractNumberCard(),

              SizedBox(height: 2.h),

              // REPLACED Property selection with searchable bottom sheet
              _buildFormSection(
                'Local *',
                GestureDetector(
                  onTap: () async {
                    final selected =
                        await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildLocalSearchBottomSheet(),
                    );

                    if (selected != null) {
                      setState(() {
                        _selectedPropertyId = selected['id'];
                        _selectedLocalData = selected;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Colors.grey[600]),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _selectedLocalData != null
                                ? '${_selectedLocalData!['numero']} - ${_selectedLocalData!['types_locaux']?['nom']}'
                                : 'Rechercher un local',
                            style: GoogleFonts.inter(
                              color: _selectedLocalData != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),

              // REPLACED Merchant selection with searchable bottom sheet
              _buildFormSection(
                'Commerçant *',
                GestureDetector(
                  onTap: () async {
                    final selected =
                        await showModalBottomSheet<Map<String, dynamic>>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _buildMerchantSearchBottomSheet(),
                    );

                    if (selected != null) {
                      setState(() {
                        _selectedMerchantId = selected['id'];
                        _selectedCommercantData = selected;
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Colors.grey[600]),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Text(
                            _selectedCommercantData != null
                                ? _selectedCommercantData!['nom']
                                : 'Rechercher un commerçant',
                            style: GoogleFonts.inter(
                              color: _selectedCommercantData != null
                                  ? Colors.black87
                                  : Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Icon(Icons.search, color: Colors.grey[600]),
                      ],
                    ),
                  ),
                ),
              ),

              // Date selection section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: Row(
                  children: [
                    // Start date
                    Expanded(
                      child: _buildFormSection(
                        'Date début *',
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dateDebut != null
                                  ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year}'
                                  : 'Sélectionner date début',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    // End date
                    Expanded(
                      child: _buildFormSection(
                        'Date fin *',
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              _dateFin != null
                                  ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                                  : 'Sélectionner date fin',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Rent amount
              _buildFormSection(
                null,
                ValidatedTextFormField(
                  controller: _rentAmountController,
                  label: 'Montant du loyer (FCFA) *',
                  hintText: 'Ex: 150000',
                  prefixIcon: Icons.attach_money,
                  suffixText: 'FCFA',
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    TextInputFormatter.withFunction((oldValue, newValue) {
                      final text = newValue.text;
                      if (text.isEmpty) return newValue;

                      final number = int.tryParse(text);
                      if (number == null) return oldValue;

                      final formatted = number.toString().replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (match) => '${match[1]} ',
                          );

                      return TextEditingValue(
                        text: formatted,
                        selection:
                            TextSelection.collapsed(offset: formatted.length),
                      );
                    }),
                  ],
                  validator: (value) {
                    if (value.isEmpty) {
                      return 'Champ requis';
                    }
                    final cleanValue = value.replaceAll(' ', '');
                    final amount = double.tryParse(cleanValue);
                    if (amount == null) {
                      return 'Montant invalide';
                    }
                    if (amount <= 0) {
                      return 'Le montant doit être positif';
                    }
                    return null;
                  },
                  dynamicHintBuilder: (value) {
                    final cleanValue = value.replaceAll(' ', '');
                    if (cleanValue.isEmpty) {
                      return 'Montant mensuel attendu pour le commerçant';
                    }
                    final amount = double.tryParse(cleanValue);
                    if (amount == null || amount <= 0) {
                      return '';
                    }
                    final weekly = amount / 4;
                    return '≈ ${_currencyFormat.format(weekly)} par semaine estimée';
                  },
                ),
              ),

              SizedBox(height: 2.h),

              // Deposit section
              _buildDepositSection(),

              SizedBox(height: 4.h),

              // Save button
              Padding(
                padding: EdgeInsets.all(4.w),
                child: SizedBox(
                  width: double.infinity,
                  height: 6.h,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _creerBail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSaving
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Text(
                                'Création en cours...',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Créer le bail',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),

              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
