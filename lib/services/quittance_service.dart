import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class QuittanceService {
  /// Génère et affiche directement la quittance PDF
  Future<void> genererQuittance(Map<String, dynamic> paiement) async {
    try {
      // Extraire données
      final bail = paiement['baux'] as Map<String, dynamic>?;
      final commercant = bail?['commercants'] as Map<String, dynamic>?;
      final local = bail?['locaux'] as Map<String, dynamic>?;

      final montant = (paiement['montant'] as num?)?.toDouble() ?? 0;
      final moisConcerne = paiement['mois_concerne'] ?? '';
      final modePaiement = paiement['mode_paiement'] ?? '';
      final nomCommercant = commercant?['nom'] ?? '';
      final numeroLocal = local?['numero'] ?? '';

      // N° quittance : QUIT-{8 premiers chars de l'ID}
      final numeroQuittance =
          'QUIT-${paiement['id'].toString().substring(0, 8)}';

      // Conversion du mois "2025-01" → "Janvier 2025"
      final moisFormate = _formatMois(moisConcerne);

      // Montant formaté "40500" → "40 500 FCFA"
      final montantFormate = _formatMontant(montant);

      // Date et heure actuelles
      final now = DateTime.now();
      final dateImpression = DateFormat('dd/MM/yyyy').format(now);
      final heureImpression = DateFormat('HH:mm:ss').format(now);

      // Créer PDF
      final pdf = pw.Document();

      // Police
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();

      // Charger le logo
      final logoData = await rootBundle.load(
        'assets/images/logo_adam_tp-1761380059966.jpg',
      );
      final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(15), // Réduction des marges
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // PREMIÈRE QUITTANCE
                _buildQuittance(
                  font: font,
                  fontBold: fontBold,
                  logoImage: logoImage,
                  numeroQuittance: numeroQuittance,
                  nomCommercant: nomCommercant,
                  numeroLocal: numeroLocal,
                  moisFormate: moisFormate,
                  montantFormate: montantFormate,
                  modePaiement: modePaiement,
                  dateImpression: dateImpression,
                  heureImpression: heureImpression,
                ),

                pw.SizedBox(height: 25), // Réduction de l'espacement
                // LIGNE DE SÉPARATION
                pw.Container(
                  width: double.infinity,
                  height: 1,
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(
                        color: PdfColors.grey300,
                        width: 1,
                        style: pw.BorderStyle.dashed,
                      ),
                    ),
                  ),
                ),

                pw.SizedBox(height: 25), // Réduction de l'espacement
                // DEUXIÈME QUITTANCE (IDENTIQUE)
                _buildQuittance(
                  font: font,
                  fontBold: fontBold,
                  logoImage: logoImage,
                  numeroQuittance: numeroQuittance,
                  nomCommercant: nomCommercant,
                  numeroLocal: numeroLocal,
                  moisFormate: moisFormate,
                  montantFormate: montantFormate,
                  modePaiement: modePaiement,
                  dateImpression: dateImpression,
                  heureImpression: heureImpression,
                ),
              ],
            );
          },
        ),
      );

      // IMPORTANT : Utilise SEULEMENT layoutPdf, pas de sauvegarde fichier
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'Quittance_$numeroQuittance.pdf',
      );

      print('✅ Quittance générée avec succès: $numeroQuittance');
    } catch (e, stackTrace) {
      print('❌ ERREUR génération quittance: $e');
      print('Stack: $stackTrace');
      rethrow; // Relance l'erreur pour affichage
    }
  }

  /// Construit une quittance selon le modèle amélioré
  pw.Widget _buildQuittance({
    required pw.Font font,
    required pw.Font fontBold,
    required pw.MemoryImage logoImage,
    required String numeroQuittance,
    required String nomCommercant,
    required String numeroLocal,
    required String moisFormate,
    required String montantFormate,
    required String modePaiement,
    required String dateImpression,
    required String heureImpression,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12), // Réduction du padding
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // EN-TÊTE AVEC LOGO
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // LOGO ADAMTP
              pw.Image(
                logoImage,
                height: 40, // Hauteur fixée à 40px
                fit: pw.BoxFit.contain,
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Locataire : $nomCommercant',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Fait le : $dateImpression à $heureImpression',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Imprimé par MICHAEL TOUMA',
                    style: pw.TextStyle(font: font, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),

          pw.SizedBox(height: 6), // Réduction de l'espacement
          // NUMÉRO LOCAL
          pw.Row(
            children: [
              pw.Text(
                'Locative : $numeroLocal',
                style: pw.TextStyle(font: font, fontSize: 12),
              ),
            ],
          ),

          pw.SizedBox(height: 8), // Réduction de l'espacement
          // TITRE QUITTANCE DE LOYER
          pw.Center(
            child: pw.Text(
              'QUITTANCE DE LOYER',
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 6), // Réduction de l'espacement
          // TEXTE LÉGAL
          pw.Text(
            'Doit être considérée comme « reçu à titre d\'indemnité d\'occupation » si le bail n\'a pas été renouvelé ou si le destinataire a reçu congé',
            style: pw.TextStyle(font: font, fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),

          pw.SizedBox(height: 8), // Réduction de l'espacement
          // TABLEAU DÉTAILS
          pw.Container(
            width: double.infinity,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 1),
              children: [
                // EN-TÊTE TABLEAU
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Détail de votre quittance n°',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'MONTANT',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Mode de paiement',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // LIGNE 1 - NUMÉRO QUITTANCE
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        numeroQuittance,
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        montantFormate,
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        modePaiement,
                        style: pw.TextStyle(font: font, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                  ],
                ),

                // LIGNE 2 - DESCRIPTION
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'Loyer de $moisFormate',
                        style: pw.TextStyle(font: font, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('', style: pw.TextStyle(font: font)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),

                // LIGNE 3 - TOTAL
                pw.TableRow(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        'TOTAL QUITTANCE',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(
                        montantFormate,
                        style: pw.TextStyle(font: fontBold, fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text('', style: pw.TextStyle(font: font)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 8), // Réduction de l'espacement
          // CLAUSES DE RÉSERVE (TEXTE COMPLET)
          pw.Container(
            width: double.infinity,
            child: pw.Text(
              'CLAUSES DE RESERVE : La présente quittance annule tous reçus remis à titre d\'accompte, ne concerne que la période indiquée et ne présume pas du paiement des quittances antérieures. Elle ne comporte pas renonciation aux droits et actions du propriétaire ni novation dont l\'occupant puisse se prévaloir. En cas de révision en cours, les versements quittancés le sont à titre provisionnel et en compte.',
              style: pw.TextStyle(font: font, fontSize: 7),
              textAlign: pw.TextAlign.justify,
            ),
          ),

          pw.SizedBox(height: 12), // Espacement avant signatures
          // SIGNATURES AVEC ESPACE ÉTENDU ET LIGNES POINTILLÉES
          pw.Container(
            height: 80, // Hauteur fixée à 80px
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // SIGNATURE ET CACHET
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Signature et Cachet',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 50),
                      // Ligne pointillée pour signature
                      pw.Container(
                        width: double.infinity,
                        height: 1,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey600,
                              width: 1,
                              style: pw.BorderStyle.dashed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(width: 20),

                // SIGNATURE CLIENT
                pw.Expanded(
                  flex: 1,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Signature client',
                        style: pw.TextStyle(font: fontBold, fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 50),
                      // Ligne pointillée pour signature
                      pw.Container(
                        width: double.infinity,
                        height: 1,
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(
                            bottom: pw.BorderSide(
                              color: PdfColors.grey600,
                              width: 1,
                              style: pw.BorderStyle.dashed,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Convertit "2025-01" → "Janvier 2025"
  String _formatMois(String moisStr) {
    if (moisStr.isEmpty) return '';

    try {
      final parts = moisStr.split('-');
      if (parts.length != 2) return moisStr;

      final year = parts[0];
      final month = int.parse(parts[1]);

      const mois = [
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
        'Décembre',
      ];

      if (month < 1 || month > 12) return moisStr;

      return '${mois[month - 1]} $year';
    } catch (e) {
      print('Erreur formatage mois: $e');
      return moisStr;
    }
  }

  /// Formate "40500" → "40 500 FCFA"
  String _formatMontant(double montant) {
    try {
      final formatter = NumberFormat('#,###', 'fr_FR');
      return '${formatter.format(montant.toInt()).replaceAll(',', ' ')} FCFA';
    } catch (e) {
      print('Erreur formatage montant: $e');
      return '${montant.toInt()} FCFA';
    }
  }
}
