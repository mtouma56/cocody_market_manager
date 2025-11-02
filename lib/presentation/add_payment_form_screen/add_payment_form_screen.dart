import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/paiements_service.dart';
import '../../widgets/animated/animated_form_section.dart';

class AddPaymentFormScreen extends StatefulWidget {
  const AddPaymentFormScreen({super.key});

  @override
  State<AddPaymentFormScreen> createState() => _AddPaymentFormScreenState();
}

class _AddPaymentFormScreenState extends State<AddPaymentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PaiementsService();
  final _montantController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBailId;
  Map<String, dynamic>? _selectedBail;
  String _modePaiement = 'Espèces';

  Map<String, dynamic>? _statutPaiements;
  String? _moisSelectionne;
  Map<String, dynamic>? _paiementExistant;

  Map<String, dynamic>? _selectedLocal;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _montantController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      // Initial loading can be empty since bottom sheet loads its own data
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _chooseBail(BuildContext context) async {
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _LocalSelectorBottomSheet(service: _service),
    );

    if (selected != null) {
      final bail = selected['baux'];
      setState(() {
        _selectedBailId = bail['id'];
        _selectedBail = bail;
        _selectedLocal = selected;
        _statutPaiements = null;
        _moisSelectionne = null;
        _paiementExistant = null;
      });

      try {
        final statut = await _service.getStatutPaiementsBail(bail['id']);
        setState(() {
          _statutPaiements = statut;
          if ((statut['arrieres'] as List).isNotEmpty) {
            _moisSelectionne = statut['arrieres'][0]['mois'] as String?;
          } else {
            _moisSelectionne = statut['mois_actuel']['mois'] as String?;
          }
        });
      } catch (e) {
        print('Erreur: $e');
      }
    }
  }

  Widget _buildLocalSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasSelection = _selectedLocal != null;

    String title = 'Rechercher un local';
    String subtitle = 'Associez ce paiement à un bail existant';

    if (hasSelection) {
      final numero = _selectedLocal!['numero'];
      final commercant = _selectedBail!['commercants']['nom'];
      title = '${numero ?? 'Local'} • $commercant';
      subtitle = 'Bail #${_selectedBail!['numero_contrat']}';
    }

    return InkWell(
      onTap: () => _chooseBail(context),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest
              .withValues(alpha: hasSelection ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasSelection
                ? colorScheme.primary.withValues(alpha: 0.45)
                : colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withValues(alpha: 0.12),
              ),
              child: Icon(Icons.storefront, color: colorScheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: hasSelection
                              ? colorScheme.onSurface
                              : colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.search, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildBailSummaryCard(BuildContext context) {
    if (_selectedBail == null) {
      return const SizedBox.shrink();
    }

    final montantLoyer =
        (_selectedBail!['montant_loyer'] as num?)?.toDouble() ?? 0;
    final frequency =
        _selectedBail!['frequence_paiement']?.toString().toLowerCase() ??
            'mensuel';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade100,
            ),
            child: const Icon(Icons.payments, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${montantLoyer.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.blue.shade800,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Loyer $frequency • ${_selectedBail!['commercants']['nom']}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blueGrey.shade700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoisSelection(BuildContext context) {
    final statut = _statutPaiements!;
    final arrieres =
        List<Map<String, dynamic>>.from(statut['arrieres'] as List);
    final tousMois =
        List<Map<String, dynamic>>.from(statut['tous_mois'] as List);
    final moisActuelSolde = statut['mois_actuel_solde'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moisActuelSolde)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Le mois en cours est déjà soldé',
                    style: TextStyle(color: Colors.green.shade900),
                  ),
                ),
              ],
            ),
          ),
        if (moisActuelSolde) const SizedBox(height: 16),
        Text(
          'Sélection du mois *',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        if (arrieres.isNotEmpty) ...[
          Text(
            'Mois en retard (${arrieres.length})',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final mois in arrieres)
            _buildMoisRadioTile(context, mois, highlightRetard: true),
          const Divider(height: 24),
        ],
        Text(
          'Autres mois disponibles',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 8),
        for (final mois in tousMois.where((m) => m['est_solde'] != true))
          _buildMoisRadioTile(context, mois),
      ],
    );
  }

  Widget _buildMoisRadioTile(
    BuildContext context,
    Map<String, dynamic> mois, {
    bool highlightRetard = false,
  }) {
    final value = mois['mois'] as String;
    final reste = (mois['reste'] as num).toDouble();
    final isCurrent = mois['est_actuel'] == true;

    return RadioListTile<String>(
      title: Text(mois['mois_label'].toString()),
      subtitle: Text('Reste: ${reste.toStringAsFixed(0)} FCFA'),
      value: value,
      groupValue: _moisSelectionne,
      onChanged: (selected) async {
        setState(() => _moisSelectionne = selected);

        if (_selectedBailId != null && selected != null) {
          final existant =
              await _service.getPaiementEnAttente(_selectedBailId!, selected);
          setState(() => _paiementExistant = existant);
        }
      },
      secondary: highlightRetard
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'RETARD',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : isCurrent
              ? const Icon(Icons.calendar_today, color: Colors.blue)
              : null,
    );
  }

  Widget _buildExistingPaymentAlert(BuildContext context) {
    if (_paiementExistant == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        border: Border.all(color: Colors.orange.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Un paiement existe déjà pour ce mois',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Montant attendu: ${(_paiementExistant!['montant'] as num).toStringAsFixed(0)} FCFA',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Text(
            'Statut: ${_paiementExistant!['statut']}',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vous pouvez valider ce paiement ou créer un paiement partiel supplémentaire.',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetails(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_paiementExistant != null) ...[
          _buildExistingPaymentAlert(context),
          const SizedBox(height: 16),
        ],
        Text(
          'Montant payé (FCFA) *',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _montantController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            hintText: 'Ex: 150000',
            prefixIcon: const Icon(Icons.payments),
            suffixText: 'FCFA',
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.12),
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          onChanged: (value) {
            if (_selectedBail != null && value.isNotEmpty) {
              setState(() {});
            }
          },
          validator: (value) {
            if (value?.isEmpty ?? true) return 'Montant requis';

            final montant = double.tryParse(value!);
            if (montant == null) return 'Montant invalide';

            if (_statutPaiements != null && _moisSelectionne != null) {
              final moisData = (_statutPaiements!['tous_mois'] as List)
                  .firstWhere((m) => m['mois'] == _moisSelectionne);
              final reste = (moisData['reste'] as num).toDouble();

              if (montant > reste) {
                return 'Maximum: ${reste.toStringAsFixed(0)} FCFA';
              }
            }

            if (montant <= 0) return 'Montant doit être > 0';

            return null;
          },
        ),
        if (_selectedBail != null && _montantController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildMontantFeedback(context),
        ],
        const SizedBox(height: 16),
        Text(
          'Mode de paiement *',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _modePaiement,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.account_balance_wallet),
          ),
          items: ['Espèces', 'Virement', 'Chèque', 'Mobile Money']
              .map(
                (mode) => DropdownMenuItem(
                  value: mode,
                  child: Text(mode),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _modePaiement = value!),
        ),
        const SizedBox(height: 16),
        Text(
          'Notes (optionnel)',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            hintText: 'Ex: Paiement partiel... ',
            prefixIcon: const Icon(Icons.note),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 24),
        if (_paiementExistant != null)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed:
                      _isSaving ? null : () => _validerPaiementExistant(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Valider le paiement existant',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('ou', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : _savePaiement,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Créer paiement partiel supplémentaire',
                    style: TextStyle(fontSize: 14, color: Colors.green),
                  ),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _savePaiement,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                        Text('Enregistrement en cours...'),
                      ],
                    )
                  : const Text(
                      'Enregistrer le paiement',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
      ],
    );
  }

  Widget _buildMontantFeedback(BuildContext context) {
    final montantSaisi = double.tryParse(_montantController.text) ?? 0;
    final montantLoyer = (_selectedBail!['montant_loyer'] as num).toDouble();
    final estTropEleve = montantSaisi > montantLoyer;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: estTropEleve ? Colors.red.shade50 : Colors.grey.shade100,
        border: estTropEleve ? Border.all(color: Colors.red, width: 2) : null,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            estTropEleve ? Icons.error_outline : Icons.info_outline,
            size: 20,
            color: estTropEleve ? Colors.red : Colors.black,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              estTropEleve
                  ? '❌ Montant supérieur au loyer (${montantLoyer.toStringAsFixed(0)} FCFA)'
                  : _calculerStatut(montantSaisi, montantLoyer),
              style: TextStyle(
                fontSize: 13,
                color: estTropEleve ? Colors.red.shade900 : Colors.black,
                fontWeight: estTropEleve ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _calculerStatut(double montant, double montantLoyer) {
    if (montant >= montantLoyer) return 'Payé (Soldé)';
    if (montant > 0)
      return 'Partiel (Reste ${(montantLoyer - montant).toStringAsFixed(0)} FCFA)';
    return 'En attente';
  }

  Future<void> _validerPaiementExistant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final montant = double.parse(_montantController.text.replaceAll(' ', ''));

      await _service.validerPaiementExistant(
        paiementId: _paiementExistant!['id'],
        montantPaye: montant,
        modePaiement: _modePaiement,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Paiement validé'),
              backgroundColor: Colors.green),
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

  Future<void> _savePaiement() async {
    if (!_formKey.currentState!.validate() || _selectedBailId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un bail'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final montant = double.parse(_montantController.text.replaceAll(' ', ''));

      await _service.createPaiement(
        bailId: _selectedBailId!,
        moisConcerne: _moisSelectionne!,
        montant: montant,
        modePaiement: _modePaiement,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Paiement enregistré'),
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
      appBar: AppBar(title: const Text('Enregistrer Paiement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    AnimatedFormSection(
                      title: 'Local et bail',
                      description:
                          'Associez le paiement au bail concerné et consultez le loyer de référence.',
                      icon: Icons.storefront,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLocalSelector(context),
                          _buildBailSummaryCard(context),
                        ],
                      ),
                    ),
                    AnimatedFormSection(
                      title: 'Mois à encaisser',
                      description: _statutPaiements != null
                          ? 'Choisissez le mois concerné et visualisez les éventuels retards.'
                          : 'Sélectionnez un bail pour afficher les mois disponibles.',
                      icon: Icons.calendar_month,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: _statutPaiements != null
                          ? _buildMoisSelection(context)
                          : const Text(
                              'Sélectionnez un bail pour voir les mois disponibles.',
                            ),
                    ),
                    AnimatedFormSection(
                      title: 'Détails du paiement',
                      description:
                          'Renseignez le montant encaissé et les informations complémentaires.',
                      icon: Icons.payments_rounded,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: _buildPaymentDetails(context),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _LocalSelectorBottomSheet extends StatefulWidget {
  final PaiementsService service;

  const _LocalSelectorBottomSheet({required this.service});

  @override
  _LocalSelectorBottomSheetState createState() =>
      _LocalSelectorBottomSheetState();
}

class _LocalSelectorBottomSheetState extends State<_LocalSelectorBottomSheet> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _locaux = [];
  List<Map<String, dynamic>> _locauxFiltres = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLocaux();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocaux() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final locaux = await widget.service.searchLocauxOccupes('');
      setState(() {
        _locaux = locaux;
        _locauxFiltres = locaux;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur de chargement: $e';
      });
      print('❌ Erreur chargement locaux: $e');
    }
  }

  void _filtrerLocaux(String query) {
    setState(() {
      if (query.isEmpty) {
        _locauxFiltres = _locaux;
      } else {
        _locauxFiltres = _locaux.where((local) {
          final numero = local['numero']?.toLowerCase() ?? '';
          final bail = local['baux'];
          final commercant = bail?['commercants'];
          final nom = commercant?['nom']?.toLowerCase() ?? '';
          final q = query.toLowerCase();
          return numero.contains(q) || nom.contains(q);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sélectionner un local',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher par local ou commerçant...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _filtrerLocaux('');
                          },
                        )
                      : null,
                ),
                onChanged: _filtrerLocaux,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_locauxFiltres.length} local(aux) trouvé(s)',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(_errorMessage, textAlign: TextAlign.center),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadLocaux,
                                child: const Text('Réessayer'),
                              ),
                            ],
                          ),
                        )
                      : _locauxFiltres.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 48, color: Colors.grey),
                                  SizedBox(height: 16),
                                  Text('Aucun local trouvé'),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: _locauxFiltres.length,
                              itemBuilder: (context, index) {
                                final local = _locauxFiltres[index];
                                final numero = local['numero'] ?? '';
                                final type =
                                    local['types_locaux']?['nom'] ?? '';
                                final etage = local['etages']?['nom'] ?? '';
                                final bail = local['baux'];
                                final commercant = bail?['commercants'];
                                final nom = commercant?['nom'] ?? 'N/A';
                                final loyer = (bail?['montant_loyer'] as num?)
                                        ?.toDouble() ??
                                    0;

                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Text(
                                      numero.isNotEmpty
                                          ? numero.substring(0, 1)
                                          : 'L',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade700),
                                    ),
                                  ),
                                  title: Text(numero,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('$type - $etage',
                                          style: const TextStyle(fontSize: 12)),
                                      Row(
                                        children: [
                                          const Icon(Icons.person,
                                              size: 12, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(nom,
                                              style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey)),
                                        ],
                                      ),
                                      Text(
                                        '${loyer.toStringAsFixed(0)} FCFA/mois',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  isThreeLine: true,
                                  trailing: const Icon(Icons.arrow_forward_ios,
                                      size: 16),
                                  onTap: () => Navigator.pop(context, local),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
