import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
// Conditional import: use dart:html for web, nothing for mobile
import 'dart:html' as html if (dart.library.html) 'dart:html';

class ExcelExportService {
  /// Exporter rapport paiements en CSV format Excel
  Future<void> exporterRapportPaiements({
    required List<dynamic> paiements,
    required DateTime dateDebut,
    required DateTime dateFin,
    required String periode,
  }) async {
    try {
      // ═══════════════════════════════════════════════════════
      // GÉNÉRER CONTENU CSV
      // ═══════════════════════════════════════════════════════

      final buffer = StringBuffer();

      // UTF-8 BOM pour compatibilité Excel
      buffer.write('\\uFEFF');

      // ═══════════════════════════════════════════════════════
      // EN-TÊTE RAPPORT
      // ═══════════════════════════════════════════════════════

      buffer.writeln('MARCHÉ COCODY SAINT JEAN');
      buffer.writeln('Rapport des paiements');
      buffer.writeln(
        'Période : $periode (${DateFormat('dd/MM/yyyy').format(dateDebut)} - ${DateFormat('dd/MM/yyyy').format(dateFin)})',
      );
      buffer.writeln(
        'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
      );
      buffer.writeln('');

      // ═══════════════════════════════════════════════════════
      // STATISTIQUES
      // ═══════════════════════════════════════════════════════

      final total = paiements.fold<double>(
        0.0,
        (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
      );

      final totalPaye = paiements
          .where((p) => p['statut'] == 'Payé')
          .fold<double>(
            0.0,
            (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
          );

      final nbPayes = paiements.where((p) => p['statut'] == 'Payé').length;
      final nbPartiels =
          paiements.where((p) => p['statut'] == 'Partiel').length;

      // Statistiques générales
      buffer.writeln('STATISTIQUES GÉNÉRALES');
      buffer.writeln('Total;${total.toStringAsFixed(0)} FCFA');
      buffer.writeln('Total payé;${totalPaye.toStringAsFixed(0)} FCFA');
      buffer.writeln('Nombre total;${paiements.length}');
      buffer.writeln('Payés;$nbPayes');
      buffer.writeln('Partiels;$nbPartiels');
      buffer.writeln('');

      // ═══════════════════════════════════════════════════════
      // TABLEAU DÉTAILLÉ DES PAIEMENTS
      // ═══════════════════════════════════════════════════════

      buffer.writeln('DÉTAIL DES PAIEMENTS');

      // En-têtes colonnes (utiliser ; pour Excel européen)
      final headers = [
        'Date',
        'Commerçant',
        'Local',
        'Activité',
        'Montant (FCFA)',
        'Mode Paiement',
        'Statut',
        'Notes',
      ];

      buffer.writeln(headers.join(';'));

      // Données des paiements
      for (var paiement in paiements) {
        final bail = paiement['baux'] as Map<String, dynamic>?;
        final commercant = bail?['commercants'] as Map<String, dynamic>?;
        final local = bail?['locaux'] as Map<String, dynamic>?;

        final date = paiement['date_paiement'] ?? '';
        final nom = commercant?['nom'] ?? 'N/A';
        final numeroLocal = local?['numero'] ?? 'N/A';
        final activite = commercant?['activite'] ?? '';
        final montant = (paiement['montant'] as num?)?.toDouble() ?? 0;
        final mode = paiement['mode_paiement'] ?? '';
        final statut = paiement['statut'] ?? '';
        final notes = paiement['notes'] ?? '';

        // Date formatée
        String dateFormatee = '';
        try {
          dateFormatee = DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
        } catch (e) {
          dateFormatee = date;
        }

        // Ligne de données (nettoyer les points-virgules dans les données)
        final row = [
          _cleanCsvData(dateFormatee),
          _cleanCsvData(nom),
          _cleanCsvData(numeroLocal),
          _cleanCsvData(activite),
          montant.toStringAsFixed(0),
          _cleanCsvData(mode),
          _cleanCsvData(statut),
          _cleanCsvData(notes),
        ];

        buffer.writeln(row.join(';'));
      }

      // ═══════════════════════════════════════════════════════
      // SAUVEGARDER ET PARTAGER FICHIER
      // ═══════════════════════════════════════════════════════

      final csvContent = buffer.toString();

      if (kIsWeb) {
        // Pour le web, utiliser le téléchargement direct
        await _downloadFileWeb(csvContent, _generateFileName(dateDebut));
      } else {
        // Pour mobile, sauvegarder et partager
        await _saveAndShareFile(csvContent, _generateFileName(dateDebut));
      }

      print('✅ Rapport Excel (CSV) généré avec succès');
    } catch (e) {
      print('❌ Erreur export Excel: $e');
      rethrow;
    }
  }

  /// Nettoyer les données pour CSV (échapper points-virgules et guillemets)
  String _cleanCsvData(String data) {
    if (data.isEmpty) return '';

    // Remplacer les points-virgules par des virgules
    String cleaned = data.replaceAll(';', ',');

    // Si contient des virgules ou des guillemets, entourer de guillemets
    if (cleaned.contains(',') ||
        cleaned.contains('"') ||
        cleaned.contains('\n')) {
      cleaned = cleaned.replaceAll('"', '""'); // Échapper les guillemets
      cleaned = '"$cleaned"';
    }

    return cleaned;
  }

  /// Générer nom de fichier
  String _generateFileName(DateTime dateDebut) {
    final dateStr = DateFormat('ddMMyyyy').format(dateDebut);
    return 'Rapport_Paiements_$dateStr.csv';
  }

  /// Téléchargement pour Web
  Future<void> _downloadFileWeb(String content, String fileName) async {
    if (kIsWeb) {
      // Utiliser l'API Web pour télécharger
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor =
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);

      html.Url.revokeObjectUrl(url);
    }
  }

  /// Sauvegarder et partager pour Mobile
  Future<void> _saveAndShareFile(String content, String fileName) async {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(content, encoding: utf8);

    print('✅ Fichier CSV sauvegardé : $filePath');

    // Partager le fichier
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: 'Rapport Paiements - Marché Cocody Saint Jean',
      text:
          'Rapport des paiements généré au format Excel (CSV)\n\nPour ouvrir dans Excel :\n1. Ouvrir Excel\n2. Fichier > Ouvrir\n3. Sélectionner le fichier CSV\n4. Choisir délimiteur "Point-virgule"',
    );
  }
}
