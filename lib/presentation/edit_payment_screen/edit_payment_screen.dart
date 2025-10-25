import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/paiements_service.dart';

class EditPaymentScreen extends StatefulWidget {
  final String paiementId;

  const EditPaymentScreen({super.key, required this.paiementId});

  @override
  State<EditPaymentScreen> createState() => _EditPaymentScreenState();
}

class _EditPaymentScreenState extends State<EditPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PaiementsService();

  late TextEditingController _montantController;
  late TextEditingController _notesController;

  Map<String, dynamic>? _paiement;
  String _selectedModePaiement = 'Espèces';
  DateTime? _datePaiement;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _modesPaiement = [
    'Espèces',
    'Virement',
    'Mobile Money',
    'Chèque'
  ];

  @override
  void initState() {
    super.initState();
    _montantController = TextEditingController();
    _notesController = TextEditingController();
    _loadPaiementData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPaiementData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPaiementDetails(widget.paiementId);
      setState(() {
        _paiement = data;
        _montantController.text =
            (data['montant'] as num?)?.toStringAsFixed(0) ?? '0';
        _notesController.text = data['notes'] ?? '';
        _selectedModePaiement = data['mode_paiement'] ?? 'Espèces';
        _datePaiement = data['date_paiement'] != null
            ? DateTime.parse(data['date_paiement'])
            : DateTime.now();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Erreur: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _datePaiement ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      locale: const Locale('fr', 'FR'),
    );

    if (picked != null) {
      setState(() {
        _datePaiement = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String _formatMois(String? moisStr) {
    if (moisStr == null) return 'N/A';
    try {
      final parts = moisStr.split('-');
      final year = parts[0];
      final month = int.parse(parts[1]);
      final mois = [
        'Janvier',
        'Février',
        'Mars',
        'Avril',
        'Mai',
        'Juin',
        'Juillet',
        'Août',
        'Septembre',
        'Octobre',
        'Novembre',
        'Décembre'
      ];
      return '${mois[month - 1]} $year';
    } catch (e) {
      return moisStr;
    }
  }

  Future<void> _savePaiement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updatePaiement(
        paiementId: widget.paiementId,
        montant: double.parse(_montantController.text.replaceAll(' ', '')),
        modePaiement: _selectedModePaiement,
        datePaiement: _datePaiement!.toIso8601String().split('T')[0],
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier Paiement')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_paiement == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Modifier Paiement')),
        body: const Center(child: Text('Erreur de chargement')),
      );
    }

    final bail = _paiement!['baux'];
    final commercant = bail?['commercants'];
    final local = bail?['locaux'];
    final moisConcerne = _formatMois(_paiement!['mois_concerne']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier Paiement'),
        backgroundColor: Colors.orange.shade50,
        foregroundColor: Colors.orange.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aperçu du paiement
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.edit, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'Modification du paiement',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text('Mois concerné: $moisConcerne'),
                      const SizedBox(height: 4),
                      Text('Commerçant: ${commercant?['nom'] ?? 'N/A'}'),
                      const SizedBox(height: 4),
                      Text('Local: ${local?['numero'] ?? 'N/A'}'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Montant
              const Text(
                'Montant du paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _montantController,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA) *',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.payments),
                  suffixText: 'FCFA',
                  helperText: 'Entrez le montant payé',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Montant requis';
                  if (double.tryParse(value!) == null) {
                    return 'Montant invalide';
                  }
                  if (double.parse(value) <= 0) return 'Montant doit être > 0';
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Mode de paiement
              const Text(
                'Mode de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Column(
                children: _modesPaiement.map((mode) {
                  return RadioListTile<String>(
                    title: Text(mode),
                    value: mode,
                    groupValue: _selectedModePaiement,
                    onChanged: (value) {
                      setState(() {
                        _selectedModePaiement = value!;
                      });
                    },
                    activeColor: Colors.orange,
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // Date de paiement
              const Text(
                'Date de paiement',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de paiement *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _formatDate(_datePaiement),
                    style: TextStyle(
                      color: _datePaiement == null ? Colors.grey : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notes
              const Text(
                'Raison de la modification',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Raison de la modification, remarques...',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 32),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePaiement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                                Text('Sauvegarde...'),
                              ],
                            )
                          : const Text(
                              'Enregistrer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Note d'information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Le statut du paiement sera automatiquement recalculé selon le montant saisi.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
