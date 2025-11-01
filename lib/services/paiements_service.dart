import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart' as intl;

class PaiementsService {
  final _supabase = Supabase.instance.client;

  // Getter public pour l'accès depuis le dashboard
  SupabaseClient get supabase => _supabase;

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
      print('🔍 Recherche locaux occupés avec query: "$query"');

      // Simplified query to get baux with proper joins - removed inner joins that might exclude records
      final bauxResponse = await _supabase
          .from('baux')
          .select('''
            id,
            statut,
            montant_loyer,
            numero_contrat,
            date_debut,
            date_fin,
            actif,
            commercant_id,
            local_id,
            locaux!baux_local_id_fkey(
              id,
              numero,
              statut,
              actif,
              type_id,
              etage_id,
              types_locaux(nom),
              etages(nom)
            ),
            commercants!baux_commercant_id_fkey(
              id,
              nom,
              activite,
              contact,
              actif
            )
          ''')
          .inFilter('statut', ['Actif', 'Expire bientôt'])
          .eq('actif', true)
          .order('created_at', ascending: false);

      print('📊 Nombre total de baux actifs trouvés: ${bauxResponse.length}');

      if (bauxResponse.isEmpty) {
        print('⚠️ Aucun bail actif trouvé dans la base');
        return [];
      }

      List<Map<String, dynamic>> baux = List<Map<String, dynamic>>.from(
        bauxResponse,
      );

      // Filter records where both local and commercant exist and are active
      baux = baux.where((bail) {
        final local = bail['locaux'];
        final commercant = bail['commercants'];

        // Skip if either local or commercant is null or inactive
        if (local == null || commercant == null) {
          print('⚠️ Bail ${bail['id']} ignoré - données manquantes');
          return false;
        }

        // Skip if local or commercant is inactive
        if (local['actif'] != true || commercant['actif'] != true) {
          print(
            '⚠️ Bail ${bail['id']} ignoré - local ou commerçant inactif',
          );
          return false;
        }

        return true;
      }).toList();

      // Filter based on search query if provided
      if (query.isNotEmpty) {
        final queryLower = query.toLowerCase();
        baux = baux.where((bail) {
          final local = bail['locaux'];
          final commercant = bail['commercants'];

          final numeroLocal = (local?['numero'] ?? '').toString().toLowerCase();
          final nomCommercant =
              (commercant?['nom'] ?? '').toString().toLowerCase();

          return numeroLocal.contains(queryLower) ||
              nomCommercant.contains(queryLower);
        }).toList();

        print('🔍 Après filtrage par "$query": ${baux.length} résultats');
      }

      // Transform baux data to have local as root with baux nested - improved transformation
      final locauxTransformes = baux
          .map((bail) {
            final local = bail['locaux'];
            if (local == null) {
              print('⚠️ Local null pour bail ${bail['id']}');
              return null;
            }

            // Create properly structured response with all necessary fields
            return {
              'id': local['id'],
              'numero': local['numero'],
              'statut': local['statut'],
              'actif': local['actif'],
              'type_id': local['type_id'],
              'etage_id': local['etage_id'],
              'types_locaux': local['types_locaux'],
              'etages': local['etages'],
              'baux': {
                'id': bail['id'],
                'statut': bail['statut'],
                'montant_loyer': bail['montant_loyer'],
                'numero_contrat': bail['numero_contrat'],
                'date_debut': bail['date_debut'],
                'date_fin': bail['date_fin'],
                'actif': bail['actif'],
                'commercants': bail['commercants'],
              },
            };
          })
          .where((item) => item != null)
          .cast<Map<String, dynamic>>()
          .toList();

      print('✅ Locaux transformés: ${locauxTransformes.length}');

      // Debug: Print first few items to verify structure
      if (locauxTransformes.isNotEmpty) {
        print(
          '📝 Premier local transformé: ${locauxTransformes.first['numero']} - ${locauxTransformes.first['baux']['commercants']['nom']}',
        );
      }

      return locauxTransformes;
    } catch (e, stackTrace) {
      print('❌ ERREUR searchLocauxOccupes: $e');
      print('📍 Stack trace: $stackTrace');
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
      'Décembre',
    ];
    return '${mois[date.month - 1]} ${date.year}';
  }

  // Vérifie si un paiement en attente existe pour ce bail et ce mois
  Future<Map<String, dynamic>?> getPaiementEnAttente(
    String bailId,
    String moisConcerne,
  ) async {
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

  // Récupère détails complets d'un paiement
  Future<Map<String, dynamic>> getPaiementDetails(String paiementId) async {
    try {
      // Validation de l'ID avant la requête
      if (paiementId.isEmpty) {
        throw Exception('ID de paiement vide');
      }

      // Vérification format UUID
      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      if (!uuidRegex.hasMatch(paiementId)) {
        throw Exception('Format d\'ID de paiement invalide: $paiementId');
      }

      print('🔍 Récupération paiement ID: $paiementId');

      final paiement = await _supabase.from('paiements').select('''
          *,
          baux!inner(
            *,
            locaux!inner(*, types_locaux(*), etages(*)),
            commercants(*)
          )
        ''').eq('id', paiementId).single();

      print('✅ Paiement récupéré avec succès');
      return paiement;
    } catch (e) {
      print('❌ ERREUR getPaiementDetails: $e');

      if (e.toString().contains(
            'JSON object requested, multiple (or no) rows returned',
          )) {
        throw Exception('Paiement non trouvé avec l\'ID: $paiementId');
      } else if (e.toString().contains('invalid input syntax for type uuid')) {
        throw Exception('ID de paiement invalide (format UUID requis)');
      } else {
        throw Exception(
          'Erreur lors du chargement du paiement: ${e.toString()}',
        );
      }
    }
  }

  // Met à jour un paiement
  Future<Map<String, dynamic>> updatePaiement({
    required String paiementId,
    required double montant,
    required String modePaiement,
    required String datePaiement,
    String? notes,
  }) async {
    try {
      // Récupère les infos du paiement pour calculer le nouveau statut
      final paiement = await _supabase
          .from('paiements')
          .select('bail_id, mois_concerne')
          .eq('id', paiementId)
          .single();

      final bailId = paiement['bail_id'];
      final moisConcerne = paiement['mois_concerne'];

      // Récupère le montant du loyer pour ce bail
      final bail = await _supabase
          .from('baux')
          .select('montant_loyer')
          .eq('id', bailId)
          .single();

      final montantLoyer = (bail['montant_loyer'] as num).toDouble();

      // Calcule le nouveau statut
      String nouveauStatut;
      if (montant >= montantLoyer) {
        nouveauStatut = 'Payé';
      } else if (montant > 0) {
        nouveauStatut = 'Partiel';
      } else {
        nouveauStatut = 'En attente';
      }

      // Vérifie si en retard
      final moisDate = DateTime.parse('$moisConcerne-01');
      final dateEcheance = DateTime(moisDate.year, moisDate.month, 10);
      final now = DateTime.now();

      if (nouveauStatut != 'Payé' && now.isAfter(dateEcheance)) {
        nouveauStatut = 'En retard';
      }

      // Met à jour le paiement
      final response = await _supabase
          .from('paiements')
          .update({
            'montant': montant,
            'mode_paiement': modePaiement,
            'date_paiement': datePaiement,
            'statut': nouveauStatut,
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
      print('❌ ERREUR updatePaiement: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer les paiements du jour avec statuts spécifiques
  Future<List<Map<String, dynamic>>> getPaiementsAujourdhui() async {
    try {
      final now = DateTime.now();
      final dateDebut = intl.DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, now.day));
      final dateFin = intl.DateFormat(
        'yyyy-MM-dd',
      ).format(DateTime(now.year, now.month, now.day + 1));

      final paiements = await _supabase
          .from('paiements')
          .select('''
          *,
          baux!inner(
            numero_contrat,
            commercants(nom, activite),
            locaux(numero)
          )
        ''')
          .gte('date_paiement', dateDebut)
          .lt('date_paiement', dateFin)
          .inFilter('statut', ['Payé', 'Partiel'])
          .order('date_paiement', ascending: false);

      return List<Map<String, dynamic>>.from(paiements);
    } catch (e) {
      print('❌ ERREUR getPaiementsAujourdhui: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer les paiements en retard avec montant initial
  Future<List<Map<String, dynamic>>> getPaiementsEnRetard() async {
    try {
      final paiements = await _supabase.from('paiements').select('''
          *,
          baux!inner(
            numero_contrat,
            montant_loyer,
            commercants(nom, activite),
            locaux(numero)
          )
        ''').eq('statut', 'En retard').order('date_echeance', ascending: true);

      // Ajouter le montant_initial pour chaque paiement
      final paiementsAvecMontantInitial = paiements.map((p) {
        final bail = p['baux'] as Map<String, dynamic>?;
        final montantLoyer = bail?['montant_loyer'];

        return {...p, 'montant_initial': montantLoyer ?? p['montant']};
      }).toList();

      return List<Map<String, dynamic>>.from(paiementsAvecMontantInitial);
    } catch (e) {
      print('❌ ERREUR getPaiementsEnRetard: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour récupérer les paiements en attente
  Future<List<Map<String, dynamic>>> getPaiementsEnAttente() async {
    try {
      final paiements = await _supabase.from('paiements').select('''
          *,
          baux!inner(
            numero_contrat,
            montant_loyer,
            commercants(nom, activite),
            locaux(numero)
          )
        ''').eq('statut', 'En attente').order('date_echeance', ascending: true);

      return List<Map<String, dynamic>>.from(paiements);
    } catch (e) {
      print('❌ ERREUR getPaiementsEnAttente: $e');
      rethrow;
    }
  }

  // NOUVELLE MÉTHODE - Génération automatique de paiements pour un mois UNIQUEMENT pour baux actifs
  Future<List<Map<String, dynamic>>> genererPaiementsMois(
      String moisConcerne) async {
    try {
      print('🔄 Génération paiements pour $moisConcerne');

      // CRITIQUE : Récupérer UNIQUEMENT les baux ACTIFS
      final bauxActifs = await _supabase
          .from('baux')
          .select('''
          id,
          local_id,
          commercant_id,
          montant_loyer,
          statut,
          locaux!inner(
            numero,
            types_locaux!inner(nom)
          ),
          commercants(nom)
        ''')
          .eq('statut', 'Actif') // ← FILTRE ESSENTIEL
          .order('created_at', ascending: false);

      print('📊 Baux actifs trouvés : ${bauxActifs.length}');

      if (bauxActifs.isEmpty) {
        print('⚠️ Aucun bail actif, aucun paiement à générer');
        return [];
      }

      // Vérifier si paiements déjà générés pour ce mois
      final paiementsExistants = await _supabase
          .from('paiements')
          .select('bail_id')
          .eq('mois_concerne', moisConcerne);

      final bailsDejaGeneres =
          paiementsExistants.map((p) => p['bail_id']).toSet();

      print('✅ Paiements déjà générés : ${bailsDejaGeneres.length}');

      // Générer paiements pour baux actifs sans paiement ce mois
      final paiementsACreer = <Map<String, dynamic>>[];

      for (var bail in bauxActifs) {
        // Vérifier si pas déjà généré
        if (bailsDejaGeneres.contains(bail['id'])) {
          print('⏭️ Bail ${bail['id']} : paiement déjà généré, skip');
          continue;
        }

        final local = bail['locaux'] as Map<String, dynamic>?;
        final commercant = bail['commercants'] as Map<String, dynamic>?;
        final loyer = (bail['montant_loyer'] as num?)?.toDouble() ?? 0;

        print(
            '➕ Génération paiement : ${commercant?['nom']} - Local ${local?['numero']} - ${loyer.toStringAsFixed(0)} FCFA');

        paiementsACreer.add({
          'bail_id': bail['id'],
          'montant': loyer,
          'mois_concerne': moisConcerne,
          'statut': 'En attente',
          'date_echeance': _calculerDateEcheance(moisConcerne),
        });
      }

      // Insérer en masse
      if (paiementsACreer.isNotEmpty) {
        await _supabase.from('paiements').insert(paiementsACreer);
        print('✅ ${paiementsACreer.length} paiements créés');
      } else {
        print('ℹ️ Aucun nouveau paiement à créer');
      }

      return paiementsACreer;
    } catch (e) {
      print('❌ Erreur génération : $e');
      rethrow;
    }
  }

  // Calculer date d'échéance (5 du mois)
  String _calculerDateEcheance(String moisConcerne) {
    try {
      final parts = moisConcerne.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      return '$year-${month.toString().padLeft(2, '0')}-05';
    } catch (e) {
      return '$moisConcerne-05';
    }
  }
}
