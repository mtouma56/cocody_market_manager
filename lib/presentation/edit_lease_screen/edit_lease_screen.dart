import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/leases_service.dart';

class EditLeaseScreen extends StatefulWidget {
  final Map<String, dynamic> bail;

  const EditLeaseScreen({super.key, required this.bail});

  @override
  State<EditLeaseScreen> createState() => _EditLeaseScreenState();
}

class _EditLeaseScreenState extends State<EditLeaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = LeasesService();

  late TextEditingController _loyerController;
  late TextEditingController _cautionController;
  late TextEditingController _pasDePorteController;

  DateTime? _dateDebut;
  DateTime? _dateFin;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Pré-remplir avec données actuelles
    _loyerController = TextEditingController(
      text: (widget.bail['montant_loyer'] as num?)?.toStringAsFixed(0) ?? '0',
    );
    _cautionController = TextEditingController(
      text: (widget.bail['montant_caution'] as num?)?.toStringAsFixed(0) ?? '0',
    );
    _pasDePorteController = TextEditingController(
      text: (widget.bail['montant_pas_de_porte'] as num?)?.toStringAsFixed(0) ??
          '0',
    );

    _dateDebut = DateTime.parse(widget.bail['date_debut']);
    _dateFin = DateTime.parse(widget.bail['date_fin']);
  }

  @override
  void dispose() {
    _loyerController.dispose();
    _cautionController.dispose();
    _pasDePorteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDebut) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDebut ? _dateDebut! : _dateFin!,
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
    );

    if (picked != null) {
      setState(() {
        if (isDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  void _prolongerAutomatiquement(int annees) {
    setState(() {
      _dateFin = DateTime(
        _dateFin!.year + annees,
        _dateFin!.month,
        _dateFin!.day,
      );
    });
  }

  Future<void> _saveBail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _service.updateBail(
        bailId: widget.bail['id'],
        dateDebut: _dateDebut!.toIso8601String().split('T')[0],
        dateFin: _dateFin!.toIso8601String().split('T')[0],
        montantLoyer: double.parse(_loyerController.text.replaceAll(' ', '')),
        caution: double.parse(_cautionController.text.replaceAll(' ', '')),
        pasDePorte:
            double.parse(_pasDePorteController.text.replaceAll(' ', '')),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Bail modifié avec succès'),
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
    final commercant = widget.bail['commercants'];
    final local = widget.bail['locaux'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le bail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Infos bail
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bail ${widget.bail['numero_contrat']}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${commercant?['nom']} - Local ${local?['numero']}',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Dates
              const Text(
                'Dates du bail',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date début *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_dateDebut!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date fin *',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.event),
                            ),
                            child: Text(
                              DateFormat('dd/MM/yyyy').format(_dateFin!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Boutons prolongation
              Wrap(
                spacing: 8,
                children: [
                  const Text(
                    'Prolonger automatiquement:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  ActionChip(
                    label: const Text('+1 an'),
                    onPressed: () => _prolongerAutomatiquement(1),
                    backgroundColor: Colors.blue.shade50,
                  ),
                  ActionChip(
                    label: const Text('+2 ans'),
                    onPressed: () => _prolongerAutomatiquement(2),
                    backgroundColor: Colors.blue.shade50,
                  ),
                  ActionChip(
                    label: const Text('+3 ans'),
                    onPressed: () => _prolongerAutomatiquement(3),
                    backgroundColor: Colors.blue.shade50,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Montants
              const Text(
                'Montants',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              const Text(
                'Loyer mensuel (FCFA) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _loyerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.payments),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Loyer requis';
                  if (double.tryParse(value!) == null) {
                    return 'Montant invalide';
                  }
                  if (double.parse(value) <= 0) return 'Montant doit être > 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Caution (FCFA) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cautionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Caution requise';
                  if (double.tryParse(value!) == null) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              const Text(
                'Pas de porte (FCFA) *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pasDePorteController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.door_front_door),
                  suffixText: 'FCFA',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Pas de porte requis';
                  if (double.tryParse(value!) == null) {
                    return 'Montant invalide';
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
                  onPressed: _isSaving ? null : _saveBail,
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
