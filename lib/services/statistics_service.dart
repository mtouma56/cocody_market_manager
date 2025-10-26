import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class StatisticsService {
  final supabase = Supabase.instance.client;

  /// Récupérer évolution des revenus sur X mois
  Future<Map<String, double>> getEvolutionRevenus(int nbMois) async {
    try {
      final now = DateTime.now();
      final dateDebut = DateTime(now.year, now.month - nbMois, 1);

      final paiements = await supabase
          .from('paiements')
          .select('montant, date_paiement, statut')
          .inFilter('statut', ['Payé', 'Partiel'])
          .gte('date_paiement', dateDebut.toIso8601String())
          .order('date_paiement');

      // Grouper par mois
      Map<String, double> revenus = {};

      for (var p in paiements) {
        final date = DateTime.parse(p['date_paiement']);
        final mois = DateFormat('MMM yyyy', 'fr_FR').format(date);
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;

        revenus[mois] = (revenus[mois] ?? 0) + montant;
      }

      return revenus;
    } catch (e) {
      print('❌ Erreur évolution revenus: $e');
      return {};
    }
  }

  /// Top N commerçants par revenu total
  Future<List<Map<String, dynamic>>> getTopCommercants(int limit) async {
    try {
      final paiements = await supabase.from('paiements').select('''
          montant,
          statut,
          baux!inner(
            commercants!inner(id, nom)
          )
        ''').inFilter('statut', ['Payé', 'Partiel']);

      // Grouper par commerçant
      Map<String, double> totaux = {};
      Map<String, String> noms = {};

      for (var p in paiements) {
        final bail = p['baux'] as Map<String, dynamic>?;
        final commercant = bail?['commercants'] as Map<String, dynamic>?;
        final id = commercant?['id'] ?? '';
        final nom = commercant?['nom'] ?? 'N/A';
        final montant = (p['montant'] as num?)?.toDouble() ?? 0;

        if (id.isNotEmpty) {
          totaux[id] = (totaux[id] ?? 0) + montant;
          noms[id] = nom;
        }
      }

      // Trier et limiter
      var sorted = totaux.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sorted
          .take(limit)
          .map((e) => {
                'id': e.key,
                'nom': noms[e.key] ?? 'N/A',
                'total': e.value,
              })
          .toList();
    } catch (e) {
      print('❌ Erreur top commerçants: $e');
      return [];
    }
  }

  /// Répartition paiements par mode
  Future<Map<String, int>> getRepartitionModesPaiement() async {
    try {
      final paiements = await supabase
          .from('paiements')
          .select('mode_paiement')
          .inFilter('statut', ['Payé', 'Partiel']);

      Map<String, int> repartition = {};

      for (var p in paiements) {
        final mode = p['mode_paiement'] ?? 'Non spécifié';
        repartition[mode] = (repartition[mode] ?? 0) + 1;
      }

      return repartition;
    } catch (e) {
      print('❌ Erreur répartition modes: $e');
      return {};
    }
  }

  /// Comparaison mois actuel vs mois précédent
  Future<Map<String, dynamic>> getComparaisonMois() async {
    try {
      final now = DateTime.now();
      final debutMoisActuel = DateTime(now.year, now.month, 1);
      final debutMoisPrecedent = DateTime(now.year, now.month - 1, 1);

      // Mois actuel
      final paiementsMoisActuel = await supabase
          .from('paiements')
          .select('montant')
          .inFilter('statut', ['Payé', 'Partiel']).gte(
              'date_paiement', debutMoisActuel.toIso8601String());

      final totalActuel = paiementsMoisActuel.fold<double>(
        0,
        (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
      );

      // Mois précédent
      final paiementsMoisPrecedent = await supabase
          .from('paiements')
          .select('montant')
          .inFilter('statut', ['Payé', 'Partiel'])
          .gte('date_paiement', debutMoisPrecedent.toIso8601String())
          .lt('date_paiement', debutMoisActuel.toIso8601String());

      final totalPrecedent = paiementsMoisPrecedent.fold<double>(
        0,
        (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
      );

      // Calculer variation
      final variation = totalPrecedent > 0
          ? ((totalActuel - totalPrecedent) / totalPrecedent) * 100
          : 0.0;

      return {
        'actuel': totalActuel,
        'precedent': totalPrecedent,
        'variation': variation,
      };
    } catch (e) {
      print('❌ Erreur comparaison: $e');
      return {
        'actuel': 0.0,
        'precedent': 0.0,
        'variation': 0.0,
      };
    }
  }
}
