import 'package:supabase_flutter/supabase_flutter.dart';

class PaiementsService {
  final _supabase = Supabase.instance.client;

  // Récupère tous les paiements
  Future<List<Map<String, dynamic>>> getPaiements({String? statut}) async {
    var query = _supabase.from('paiements').select('''
      *,
      baux!inner(
        *,
        locaux!inner(*, types_locaux(*), etages(*)),
        commercants(*)
      )
    ''').order('created_at', ascending: false);

    if (statut != null) {
      query = _supabase.from('paiements').select('''
        *,
        baux!inner(
          *,
          locaux!inner(*, types_locaux(*), etages(*)),
          commercants(*)
        )
      ''').eq('statut', statut).order('created_at', ascending: false);
    }
    return List<Map<String, dynamic>>.from(await query);
  }

  // Récupère baux actifs avec recherche
  Future<List<Map<String, dynamic>>> searchBauxActifs(String query) async {
    final baux = await _supabase.from('baux').select('''
      *,
      locaux!inner(*, types_locaux(*), etages(*)),
      commercants(*)
    ''').eq('statut', 'Actif');

    if (query.isEmpty) return List<Map<String, dynamic>>.from(baux);

    return List<Map<String, dynamic>>.from(
      baux.where((b) {
        final numero = b['locaux']?['numero']?.toLowerCase() ?? '';
        final commercant = b['commercants']?['nom']?.toLowerCase() ?? '';
        final q = query.toLowerCase();
        return numero.contains(q) || commercant.contains(q);
      }),
    );
  }

  // Récupère locaux occupés (avec bail actif)
  Future<List<Map<String, dynamic>>> searchLocauxOccupes(String query) async {
    try {
      // First get all active leases with their related data
      final baux = await _supabase.from('baux').select('''
        *,
        locaux!inner(*, types_locaux(*), etages(*)),
        commercants(*)
      ''').eq('statut', 'Actif').eq('locaux.statut', 'Occupé');

      if (query.isEmpty) {
        // Transform baux data to have local as root with baux nested
        return List<Map<String, dynamic>>.from(baux.map((bail) {
          final local = bail['locaux'];
          return {
            ...local,
            'baux': {
              'id': bail['id'],
              'statut': bail['statut'],
              'montant_loyer': bail['montant_loyer'],
              'numero_contrat': bail['numero_contrat'],
              'date_debut': bail['date_debut'],
              'date_fin': bail['date_fin'],
              'commercants': bail['commercants'],
            },
          };
        }));
      }

      // Filter based on query
      final filteredBaux = baux.where((bail) {
        final numero = bail['locaux']?['numero']?.toLowerCase() ?? '';
        final commercant = bail['commercants']?['nom']?.toLowerCase() ?? '';
        final q = query.toLowerCase();
        return numero.contains(q) || commercant.contains(q);
      }).toList();

      // Transform filtered data
      return List<Map<String, dynamic>>.from(filteredBaux.map((bail) {
        final local = bail['locaux'];
        return {
          ...local,
          'baux': {
            'id': bail['id'],
            'statut': bail['statut'],
            'montant_loyer': bail['montant_loyer'],
            'numero_contrat': bail['numero_contrat'],
            'date_debut': bail['date_debut'],
            'date_fin': bail['date_fin'],
            'commercants': bail['commercants'],
          },
        };
      }));
    } catch (e) {
      print('❌ ERREUR searchLocauxOccupes: $e');
      return [];
    }
  }

  // Vérifie paiements existants pour un bail
  Future<Map<String, dynamic>> getStatutPaiementsBail(String bailId) async {
    try {
      final bail = await _supabase
          .from('baux')
          .select('montant_loyer, date_debut')
          .eq('id', bailId)
          .single();

      final montantLoyer = (bail['montant_loyer'] as num).toDouble();
      final dateDebut = DateTime.parse(bail['date_debut']);

      final paiements = await _supabase
          .from('paiements')
          .select()
          .eq('bail_id', bailId)
          .order('mois_concerne');

      final now = DateTime.now();
      final moisActuel = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      List<Map<String, dynamic>> moisDisponibles = [];
      DateTime moisCourant = DateTime(dateDebut.year, dateDebut.month);

      while (moisCourant.isBefore(now) || moisCourant.month == now.month) {
        final moisKey =
            '${moisCourant.year}-${moisCourant.month.toString().padLeft(2, '0')}';

        final paiementsMois =
            paiements.where((p) => p['mois_concerne'] == moisKey).toList();
        final totalPaye = paiementsMois.fold<double>(
          0,
          (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
        );

        final reste = montantLoyer - totalPaye;
        final estSolde = reste <= 0;

        moisDisponibles.add({
          'mois': moisKey,
          'mois_label': _formatMoisLabel(moisCourant),
          'montant_loyer': montantLoyer,
          'total_paye': totalPaye,
          'reste': reste > 0 ? reste : 0,
          'est_solde': estSolde,
          'est_actuel': moisKey == moisActuel,
        });

        moisCourant = DateTime(moisCourant.year, moisCourant.month + 1);
      }

      final moisActuelData = moisDisponibles.firstWhere(
        (m) => m['mois'] == moisActuel,
        orElse: () => {},
      );

      final moisEnRetard = moisDisponibles.where((m) {
        final moisDate = DateTime.parse('${m['mois']}-01');
        return !m['est_solde'] &&
            moisDate.isBefore(DateTime(now.year, now.month));
      }).toList();

      return {
        'mois_actuel_solde': moisActuelData['est_solde'] ?? false,
        'mois_actuel': moisActuelData,
        'arrieres': moisEnRetard,
        'tous_mois': moisDisponibles,
        'montant_loyer': montantLoyer,
      };
    } catch (e) {
      print('❌ ERREUR getStatutPaiementsBail: $e');
      rethrow;
    }
  }

  String _formatMoisLabel(DateTime date) {
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
    return '${mois[date.month - 1]} ${date.year}';
  }

  // Vérifie si un paiement en attente existe pour ce bail et ce mois
  Future<Map<String, dynamic>?> getPaiementEnAttente(
      String bailId, String moisConcerne) async {
    try {
      final result = await _supabase
          .from('paiements')
          .select('''
            *,
            baux!inner(
              *,
              locaux!inner(*, types_locaux(*), etages(*)),
              commercants(*)
            )
          ''')
          .eq('bail_id', bailId)
          .eq('mois_concerne', moisConcerne)
          .inFilter('statut', ['En attente', 'En retard'])
          .maybeSingle();

      return result;
    } catch (e) {
      print('❌ ERREUR getPaiementEnAttente: $e');
      return null;
    }
  }

  // Valide un paiement existant
  Future<Map<String, dynamic>> validerPaiementExistant({
    required String paiementId,
    required double montantPaye,
    required String modePaiement,
    String? notes,
  }) async {
    try {
      final paiement = await _supabase
          .from('paiements')
          .select('montant, bail_id')
          .eq('id', paiementId)
          .single();

      final montantAttendu = (paiement['montant'] as num).toDouble();

      String nouveauStatut;
      if (montantPaye >= montantAttendu) {
        nouveauStatut = 'Payé';
      } else if (montantPaye > 0) {
        nouveauStatut = 'Partiel';
      } else {
        nouveauStatut = 'En attente';
      }

      final response = await _supabase
          .from('paiements')
          .update({
            'montant': montantPaye,
            'statut': nouveauStatut,
            'mode_paiement': modePaiement,
            'date_paiement': DateTime.now().toIso8601String().split('T')[0],
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', paiementId)
          .select('''
            *,
            baux!inner(
              *,
              locaux!inner(*, types_locaux(*), etages(*)),
              commercants(*)
            )
          ''')
          .single();

      return response;
    } catch (e) {
      print('❌ ERREUR validerPaiementExistant: $e');
      rethrow;
    }
  }

  // Modifie createPaiement pour accepter moisConcerne
  Future<Map<String, dynamic>> createPaiement({
    required String bailId,
    required String moisConcerne,
    required double montant,
    required String modePaiement,
    String? notes,
  }) async {
    try {
      final bail = await _supabase
          .from('baux')
          .select('montant_loyer')
          .eq('id', bailId)
          .single();

      final montantLoyer = (bail['montant_loyer'] as num).toDouble();

      final paiementsExistants = await _supabase
          .from('paiements')
          .select('montant')
          .eq('bail_id', bailId)
          .eq('mois_concerne', moisConcerne);

      final dejaPaye = paiementsExistants.fold<double>(
        0,
        (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
      );

      final nouveauTotal = dejaPaye + montant;

      String statut;
      if (nouveauTotal >= montantLoyer) {
        statut = 'Payé';
      } else if (nouveauTotal > 0) {
        statut = 'Partiel';
      } else {
        statut = 'En attente';
      }

      final moisDate = DateTime.parse('$moisConcerne-01');
      final now = DateTime.now();
      final dateEcheance = DateTime(moisDate.year, moisDate.month, 10);

      if (statut != 'Payé' && now.isAfter(dateEcheance)) {
        statut = 'En retard';
      }

      final response = await _supabase.from('paiements').insert({
        'bail_id': bailId,
        'montant': montant,
        'date_paiement': DateTime.now().toIso8601String().split('T')[0],
        'date_echeance':
            '${moisDate.year}-${moisDate.month.toString().padLeft(2, '0')}-10',
        'mois_concerne': moisConcerne,
        'statut': statut,
        'mode_paiement': modePaiement,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      }).select('''
        *,
        baux!inner(
          *,
          locaux!inner(*, types_locaux(*), etages(*)),
          commercants(*)
        )
      ''').single();

      return response;
    } catch (e) {
      print('❌ ERREUR createPaiement: $e');
      rethrow;
    }
  }
}
