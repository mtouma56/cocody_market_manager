import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class RapportService {
  Future<void> genererRapportPDF({
    required List<dynamic> paiements,
    required DateTime dateDebut,
    required DateTime dateFin,
    required String periode,
    String typeRapport = 'Tous',
  }) async {
    final pdf = pw.Document();

    // Charger le logo ADAM TP
    final logoData = await rootBundle.load(
      'assets/images/logo_adam_tp-1761388211763.jpg',
    );
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    // Calculs avec logique spéciale pour partiels en retard
    final total = paiements.fold<double>(
      0.0,
      (sum, p) {
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;
        final montantInitial =
            (p['montant_initial'] as num?)?.toDouble() ?? montant;
        final statut = p['statut'] ?? '';

        // Pour les partiels en retard, utiliser le montant restant
        if (statut == 'En retard' && montant < montantInitial) {
          return sum + (montantInitial - montant);
        }
        return sum + montant;
      },
    );

    final totalPaye = paiements
        .where((p) => p['statut'] == 'Payé')
        .fold<double>(
            0.0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));

    final totalPartiel = paiements
        .where((p) => p['statut'] == 'Partiel')
        .fold<double>(
            0.0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));

    final totalAttente = paiements
        .where((p) => p['statut'] == 'En attente')
        .fold<double>(
            0.0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));

    final totalRetard = paiements
        .where((p) => p['statut'] == 'En retard')
        .fold<double>(0.0, (sum, p) {
      final montant = (p['montant'] as num?)?.toDouble() ?? 0;
      final montantInitial =
          (p['montant_initial'] as num?)?.toDouble() ?? montant;
      // Pour les partiels en retard, calculer le montant restant
      if (montant < montantInitial) {
        return sum + (montantInitial - montant);
      }
      return sum + montant;
    });

    final nbPayes = paiements.where((p) => p['statut'] == 'Payé').length;
    final nbPartiels = paiements.where((p) => p['statut'] == 'Partiel').length;
    final nbAttente =
        paiements.where((p) => p['statut'] == 'En attente').length;
    final nbRetard = paiements.where((p) => p['statut'] == 'En retard').length;

    // Compter les partiels en retard séparément
    final nbPartielsEnRetard = paiements.where((p) {
      final statut = p['statut'] ?? '';
      final montant = (p['montant'] as num?)?.toDouble() ?? 0;
      final montantInitial =
          (p['montant_initial'] as num?)?.toDouble() ?? montant;
      return statut == 'En retard' && montant < montantInitial;
    }).length;

    // Grouper par mode de paiement
    final parMode = <String, double>{};
    for (var p in paiements) {
      final mode = p['mode_paiement'] ?? 'Non spécifié';
      final montant = (p['montant'] as num?)?.toDouble() ?? 0;
      parMode[mode] = (parMode[mode] ?? 0) + montant;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // En-tête corrigé avec alignement parfait
          pw.Container(
            height: 65, // Hauteur fixe pour alignement correct
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Section gauche avec logo et nom de l'entreprise
                pw.Expanded(
                  flex: 3,
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Container(
                        width: 50,
                        height: 50,
                        child: pw.Image(
                          logoImage,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              'ADAM TP',
                              style: pw.TextStyle(
                                fontSize: 18,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green700,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'MARCHÉ COCODY SAINT JEAN',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.grey800,
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'Rapport des paiements${typeRapport != 'Tous' ? ' - $typeRapport' : ''}',
                              style: pw.TextStyle(
                                fontSize: 12,
                                color: PdfColors.grey600,
                                fontStyle: pw.FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Section droite avec informations de période - alignement corrigé
                pw.Expanded(
                  flex: 2,
                  child: pw.Container(
                    height: 65,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Text(
                            typeRapport == 'Paiements en retard' ||
                                    typeRapport == 'Paiements en attente'
                                ? 'Période : Toutes périodes'
                                : 'Période : $periode',
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.grey800,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        if (typeRapport != 'Paiements en retard' &&
                            typeRapport != 'Paiements en attente')
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(vertical: 1),
                            child: pw.Text(
                              'Du ${DateFormat('dd/MM/yyyy').format(dateDebut)} au ${DateFormat('dd/MM/yyyy').format(dateFin)}',
                              style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey700,
                              ),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        pw.Container(
                          padding: const pw.EdgeInsets.only(top: 4),
                          child: pw.Text(
                            'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
                            style: pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey500,
                              fontStyle: pw.FontStyle.italic,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Note explicative spéciale pour rapports en retard/attente
          if (typeRapport == 'Paiements en retard' ||
              typeRapport == 'Paiements en attente') ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _getTypeRapportColor(typeRapport),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(
                    _getTypeRapportIcon(typeRapport),
                    size: 16,
                    color: PdfColors.white,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      typeRapport == 'Paiements en retard'
                          ? 'Ce rapport englobe TOUS les paiements en retard, sans exception de période. Les montants affichés correspondent aux sommes dues (montant initial pour paiements non payés, montant restant pour paiements partiels).'
                          : 'Ce rapport englobe TOUS les paiements en attente, sans exception de période. Ces montants ne sont pas encore encaissés.',
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ] else if (typeRapport != 'Tous') ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: _getTypeRapportColor(typeRapport),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(
                    _getTypeRapportIcon(typeRapport),
                    size: 16,
                    color: PdfColors.white,
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      _getTypeRapportDescription(typeRapport),
                      style: pw.TextStyle(fontSize: 10, color: PdfColors.white),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
          ],

          // Statistiques avec informations spéciales
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: typeRapport == 'Paiements en retard'
                        ? PdfColors.red50
                        : PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                          typeRapport == 'Paiements en retard'
                              ? 'MONTANT DÛ'
                              : typeRapport == 'Paiements en attente'
                                  ? 'MONTANT ATTENDU'
                                  : 'TOTAL GÉNÉRAL',
                          style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${total.toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: typeRapport == 'Paiements en retard'
                              ? PdfColors.red900
                              : PdfColors.blue900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('ENCAISSÉ', style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${(totalPaye + totalPartiel).toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text('NOMBRE', style: pw.TextStyle(fontSize: 10)),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${paiements.length}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 20),

          // Information spéciale pour paiements partiels en retard
          if (nbPartielsEnRetard > 0) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Row(
                children: [
                  pw.Icon(pw.IconData(0xe88f),
                      size: 14, color: PdfColors.orange800), // info
                  pw.SizedBox(width: 6),
                  pw.Text(
                    'Dont $nbPartielsEnRetard paiement(s) partiel(s) en retard - montants restants affichés',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.orange800,
                        fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],

          // Répartition détaillée par statut
          pw.Text(
            'Répartition détaillée par statut',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(2),
            },
            children: [
              // En-tête tableau statut
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Statut',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Nombre',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Montant (FCFA)',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              // Lignes statut
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Payé',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.green800))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('$nbPayes',
                          style: pw.TextStyle(fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${totalPaye.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 9))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('Partiel',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.orange800))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('$nbPartiels',
                          style: pw.TextStyle(fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${totalPartiel.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 9))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('En attente',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.orange600))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('$nbAttente',
                          style: pw.TextStyle(fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${totalAttente.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 9))),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('En retard',
                          style: pw.TextStyle(
                              fontSize: 9, color: PdfColors.red800))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('$nbRetard',
                          style: pw.TextStyle(fontSize: 9))),
                  pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text('${totalRetard.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 9))),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 16),

          // Répartition par mode de paiement (si applicable)
          if (parMode.isNotEmpty) ...[
            pw.Text(
              'Répartition par mode de paiement',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            ...parMode.entries
                .map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 2),
                      child: pw.Text(
                        '${e.key} : ${e.value.toStringAsFixed(0)} FCFA',
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ))
                .toList(),
            pw.SizedBox(height: 20),
          ],

          // Tableau des paiements
          pw.Text(
            'Détail des paiements (${paiements.length})',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 12),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            columnWidths: typeRapport == 'Paiements en retard'
                ? {
                    0: const pw.FlexColumnWidth(2.5),
                    1: const pw.FlexColumnWidth(1.5),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                    5: const pw.FlexColumnWidth(1.5),
                  }
                : {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
            children: [
              // En-tête adapté selon le type de rapport
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: typeRapport == 'Paiements en retard'
                    ? [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Commerçant',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Local',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Initial',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Payé',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Restant',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Statut',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ]
                    : [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Commerçant',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Local',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Montant',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Mode',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Statut',
                              style: pw.TextStyle(
                                  fontSize: 9, fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
              ),

              // Lignes de données adaptées
              ...paiements.map((p) {
                final bail = p['baux'] as Map<String, dynamic>?;
                final commercant =
                    bail?['commercants'] as Map<String, dynamic>?;
                final local = bail?['locaux'] as Map<String, dynamic>?;

                final nom = commercant?['nom'] ?? 'N/A';
                final numeroLocal = local?['numero'] ?? 'N/A';
                final montant = (p['montant'] as num?)?.toDouble() ?? 0;
                final montantInitial =
                    (p['montant_initial'] as num?)?.toDouble() ?? montant;
                final mode = p['mode_paiement'] ?? '';
                final statut = p['statut'] ?? '';

                final isPartielEnRetard =
                    statut == 'En retard' && montant < montantInitial;
                final montantRestant =
                    isPartielEnRetard ? montantInitial - montant : 0;

                return pw.TableRow(
                  children: typeRapport == 'Paiements en retard'
                      ? [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child:
                                pw.Text(nom, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(numeroLocal,
                                style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${montantInitial.toStringAsFixed(0)} F',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              isPartielEnRetard
                                  ? '${montant.toStringAsFixed(0)} F'
                                  : '0 F',
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  color: isPartielEnRetard
                                      ? PdfColors.orange800
                                      : PdfColors.grey600),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              isPartielEnRetard
                                  ? '${montantRestant.toStringAsFixed(0)} F'
                                  : '${montant.toStringAsFixed(0)} F',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.red800,
                              ),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              isPartielEnRetard ? 'Partiel en retard' : statut,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: _getStatutColor(statut),
                              ),
                            ),
                          ),
                        ]
                      : [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child:
                                pw.Text(nom, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(numeroLocal,
                                style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              '${montant.toStringAsFixed(0)} F',
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child:
                                pw.Text(mode, style: pw.TextStyle(fontSize: 8)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                              statut,
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: _getStatutColor(statut),
                              ),
                            ),
                          ),
                        ],
                );
              }).toList(),
            ],
          ),
        ],
      ),
    );

    // Afficher PDF avec nom adapté
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: typeRapport == 'Paiements en retard' ||
              typeRapport == 'Paiements en attente'
          ? 'Rapport_${typeRapport.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf'
          : 'Rapport_${typeRapport.replaceAll(' ', '_')}_${DateFormat('ddMMyyyy').format(dateDebut)}.pdf',
    );
  }

  PdfColor _getTypeRapportColor(String typeRapport) {
    switch (typeRapport) {
      case 'Paiements en retard':
        return PdfColors.red600;
      case 'Paiements en attente':
        return PdfColors.orange600;
      case 'Paiements effectués':
        return PdfColors.green600;
      default:
        return PdfColors.blue600;
    }
  }

  pw.IconData _getTypeRapportIcon(String typeRapport) {
    switch (typeRapport) {
      case 'Paiements en retard':
        return const pw.IconData(0xe002); // warning
      case 'Paiements en attente':
        return const pw.IconData(0xe003); // schedule
      case 'Paiements effectués':
        return const pw.IconData(0xe876); // check_circle
      default:
        return const pw.IconData(0xe88e); // assessment
    }
  }

  String _getTypeRapportDescription(String typeRapport) {
    switch (typeRapport) {
      case 'Paiements en retard':
        return 'Ce rapport présente uniquement les paiements en retard. Aucun montant encaissé à ce jour.';
      case 'Paiements en attente':
        return 'Ce rapport présente uniquement les paiements en attente de traitement. Aucun montant encaissé à ce jour.';
      case 'Paiements effectués':
        return 'Ce rapport présente uniquement les paiements effectués (payé et partiel). Montants réellement encaissés.';
      default:
        return 'Ce rapport présente tous les types de paiements selon la période sélectionnée.';
    }
  }

  PdfColor _getStatutColor(String statut) {
    switch (statut) {
      case 'Payé':
        return PdfColors.green800;
      case 'Partiel':
        return PdfColors.orange800;
      case 'En retard':
        return PdfColors.red800;
      case 'En attente':
        return PdfColors.orange600;
      default:
        return PdfColors.grey800;
    }
  }
}
