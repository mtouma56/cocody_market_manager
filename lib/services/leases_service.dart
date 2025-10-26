import 'package:supabase_flutter/supabase_flutter.dart';

class LeasesService {
  static final LeasesService _instance = LeasesService._internal();
  factory LeasesService() => _instance;
  LeasesService._internal();

  final _supabase = Supabase.instance.client;

  /// Valide qu'une chaîne est un UUID valide
  bool _isValidUUID(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;
    final uuidRegExp = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return uuidRegExp.hasMatch(uuid);
  }

  /// Récupère tous les baux avec toutes les informations nécessaires
  Future<List<Map<String, dynamic>>> getAllLeases() async {
    try {
      final response = await _supabase.from('baux').select('''
        id,
        numero_contrat,
        statut,
        date_debut,
        date_fin,
        montant_loyer,
        actif,
        created_at,
        commercant_id,
        commercants!inner(
          id,
          nom,
          activite,
          contact,
          email,
          photo_url
        ),
        locaux!inner(
          numero,
          etages!inner(nom, ordre),
          types_locaux!inner(nom, surface_m2)
        )
      ''').eq('actif', true).order('date_debut', ascending: false);

      List<Map<String, dynamic>> leases = [];

      for (var bail in response) {
        // Calculer le prochain paiement
        DateTime nextPayment = _calculateNextPayment(bail['date_debut']);

        // Déterminer le statut d'urgence
        String urgency = _determineUrgency(
          bail['statut'],
          DateTime.parse(bail['date_fin']),
          nextPayment,
        );

        leases.add({
          'id': bail['id'],
          'contractNumber': bail['numero_contrat'],
          'merchantId': bail['commercant_id'], // ✅ AJOUT: ID du commerçant
          'tenantName': bail['commercants']['nom'],
          'tenantBusiness': bail['commercants']['activite'],
          'tenantPhone': bail['commercants']['contact'],
          'tenantEmail': bail['commercants']['email'] ?? '',
          'propertyNumber': bail['locaux']['numero'],
          'propertyType': _getPropertyTypeCode(
            bail['locaux']['types_locaux']['nom'],
          ),
          'propertyFloor': _getFloorCode(bail['locaux']['etages']['ordre']),
          'propertySize': '${bail['locaux']['types_locaux']['surface_m2']}m²',
          'monthlyRent': (bail['montant_loyer'] as num).toDouble(),
          'startDate': bail['date_debut'],
          'endDate': bail['date_fin'],
          'status': _getStatusCode(bail['statut']),
          'urgency': urgency,
          'nextPaymentDate': nextPayment.toIso8601String().split('T')[0],
          'tenantProfilePhoto': bail['commercants']['photo_url'] ??
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
          'tenantProfilePhotoSemanticLabel':
              'Photo de profil de ${bail['commercants']['nom']}, locataire du local ${bail['locaux']['numero']}',
          'createdAt': bail['created_at'],
        });
      }

      print('✅ Récupération de ${leases.length} baux depuis Supabase');
      return leases;
    } catch (error) {
      print('❌ ERREUR getAllLeases: $error');
      throw Exception('Erreur lors de la récupération des baux: $error');
    }
  }

  /// Récupère les baux par commerçant (avec validation UUID)
  Future<List<Map<String, dynamic>>> getLeasesByMerchant(
      String? merchantId) async {
    try {
      // ✅ VALIDATION: Vérifie si l'UUID du commerçant est valide
      if (!_isValidUUID(merchantId)) {
        print(
            '⚠️ UUID commerçant invalide: $merchantId - Retour de tous les baux');
        return await getAllLeases();
      }

      // ✅ FIX: Vérifier si le merchantId est null ou vide APRÈS la validation UUID
      if (merchantId == null || merchantId.isEmpty) {
        print('⚠️ MerchantId null ou vide - Retour de tous les baux');
        return await getAllLeases();
      }

      final response = await _supabase
          .from('baux')
          .select('''
        id,
        numero_contrat,
        statut,
        date_debut,
        date_fin,
        montant_loyer,
        actif,
        created_at,
        commercant_id,
        commercants!inner(
          id,
          nom,
          activite,
          contact,
          email,
          photo_url
        ),
        locaux!inner(
          numero,
          etages!inner(nom, ordre),
          types_locaux!inner(nom, surface_m2)
        )
      ''')
          .eq('actif', true)
          .eq('commercant_id',
              merchantId) // ✅ Maintenant sûr d'utiliser un UUID valide
          .order('date_debut', ascending: false);

      List<Map<String, dynamic>> leases = [];

      for (var bail in response) {
        DateTime nextPayment = _calculateNextPayment(bail['date_debut']);
        String urgency = _determineUrgency(
          bail['statut'],
          DateTime.parse(bail['date_fin']),
          nextPayment,
        );

        leases.add({
          'id': bail['id'],
          'contractNumber': bail['numero_contrat'],
          'merchantId': bail['commercant_id'], // ✅ AJOUT: ID du commerçant
          'tenantName': bail['commercants']['nom'],
          'tenantBusiness': bail['commercants']['activite'],
          'tenantPhone': bail['commercants']['contact'],
          'tenantEmail': bail['commercants']['email'] ?? '',
          'propertyNumber': bail['locaux']['numero'],
          'propertyType': _getPropertyTypeCode(
            bail['locaux']['types_locaux']['nom'],
          ),
          'propertyFloor': _getFloorCode(bail['locaux']['etages']['ordre']),
          'propertySize': '${bail['locaux']['types_locaux']['surface_m2']}m²',
          'monthlyRent': (bail['montant_loyer'] as num).toDouble(),
          'startDate': bail['date_debut'],
          'endDate': bail['date_fin'],
          'status': _getStatusCode(bail['statut']),
          'urgency': urgency,
          'nextPaymentDate': nextPayment.toIso8601String().split('T')[0],
          'tenantProfilePhoto': bail['commercants']['photo_url'] ??
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
          'tenantProfilePhotoSemanticLabel':
              'Photo de profil de ${bail['commercants']['nom']}, locataire du local ${bail['locaux']['numero']}',
          'createdAt': bail['created_at'],
        });
      }

      print(
          '✅ Récupération de ${leases.length} baux pour le commerçant $merchantId');
      return leases;
    } catch (error) {
      print('❌ ERREUR getLeasesByMerchant: $error');
      throw Exception('Erreur lors du filtrage par commerçant: $error');
    }
  }

  /// Récupère les baux expirant dans les N prochains jours
  Future<List<Map<String, dynamic>>> getExpiringLeases(
      int daysUntilExpiry) async {
    try {
      final limitDate = DateTime.now().add(Duration(days: daysUntilExpiry));

      final response = await _supabase
          .from('baux')
          .select('''
            id,
            numero_contrat,
            date_debut,
            date_fin,
            loyer_mensuel,
            statut,
            commercants!inner(
              id,
              nom,
              telephone
            ),
            locaux!inner(
              id,
              numero
            )
          ''')
          .eq('statut', 'Actif')
          .lte('date_fin', limitDate.toIso8601String())
          .order('date_fin', ascending: true);

      print('✅ Baux expirant récupérés: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération baux expirant: $e');
      throw Exception('Impossible de récupérer les baux expirant: $e');
    }
  }

  /// Met à jour le statut d'un bail (UNIQUEMENT pour résiliation manuelle)
  Future<void> updateLeaseStatus(String leaseId, String newStatus) async {
    try {
      String supabaseStatus = _getSupabaseStatus(newStatus);

      // ✅ SEULEMENT pour résiliation manuelle - Laisse le trigger gérer les autres statuts
      if (supabaseStatus == 'Résilié') {
        await _supabase
            .from('baux')
            .update({'statut': supabaseStatus}).eq('id', leaseId);

        print('✅ Bail $leaseId résilié manuellement');
      } else {
        // ✅ Pour les autres statuts, laisser le trigger automatique faire le calcul
        print(
            '⚠️ Statut automatique - Les statuts Actif/Expiré/Expire bientôt sont gérés automatiquement par la base de données');
        throw Exception(
            'Les statuts automatiques ne peuvent pas être modifiés manuellement. Utilisez updateBail() pour modifier les dates.');
      }
    } catch (error) {
      print('❌ ERREUR updateLeaseStatus: $error');
      throw Exception('Erreur lors de la mise à jour du statut: $error');
    }
  }

  /// Calcule la prochaine date de paiement
  DateTime _calculateNextPayment(String startDate) {
    DateTime start = DateTime.parse(startDate);
    DateTime now = DateTime.now();

    // Calculer le premier du mois suivant
    DateTime nextMonth = DateTime(now.year, now.month + 1, start.day);

    // Si la date est déjà passée dans le mois courant, prendre le mois suivant
    if (DateTime(now.year, now.month, start.day).isBefore(now)) {
      return nextMonth;
    } else {
      return DateTime(now.year, now.month, start.day);
    }
  }

  /// Détermine l'urgence du bail
  String _determineUrgency(
    String statut,
    DateTime endDate,
    DateTime nextPayment,
  ) {
    DateTime now = DateTime.now();

    // ✅ FIX: Support du nouveau statut Résilié
    if (statut == 'Expiré' || statut == 'Résilié') return 'high';

    // Vérification de l'expiration dans les 30 jours
    if (endDate.difference(now).inDays <= 30) return 'high';

    // Vérification du retard de paiement
    if (nextPayment.isBefore(now)) return 'high';

    // Vérification de l'expiration dans les 60 jours ou paiement dans 7 jours
    if (endDate.difference(now).inDays <= 60 ||
        nextPayment.difference(now).inDays <= 7) return 'medium';

    return 'low';
  }

  /// Convertit le code de statut en statut Supabase
  String _getSupabaseStatus(String? statusCode) {
    final safeStatusCode = statusCode ?? '';
    switch (safeStatusCode) {
      case 'active':
        return 'Actif';
      case 'expiring':
        return 'Expire bientôt';
      case 'expired':
        return 'Expiré';
      case 'terminated': // ✅ SUPPORT: Résiliation manuelle
        return 'Résilié';
      default:
        return 'Actif';
    }
  }

  /// Convertit le statut Supabase en code
  String _getStatusCode(String? supabaseStatus) {
    final safeStatus = supabaseStatus ?? '';
    switch (safeStatus) {
      case 'Actif':
        return 'active';
      case 'Expire bientôt':
        return 'expiring';
      case 'Expiré':
        return 'expired';
      case 'Résilié': // ✅ SUPPORT: Résiliation manuelle
        return 'terminated';
      default:
        return 'active';
    }
  }

  /// Convertit le nom du type en code
  String _getPropertyTypeCode(String? typeName) {
    final safeTypeName = typeName ?? '';
    switch (safeTypeName) {
      case 'Boutique 9m²':
        return '9m2_shop';
      case 'Boutique 4.5m²':
        return '4.5m2_shop';
      case 'Restaurant':
        return 'restaurant';
      case 'Banque':
        return 'bank';
      case 'Box':
        return 'box';
      case 'Étal':
        return 'market_stall';
      default:
        return '9m2_shop';
    }
  }

  /// Convertit l'ordre d'étage en code
  String _getFloorCode(int? ordre) {
    final safeOrdre = ordre ?? 0;
    switch (safeOrdre) {
      case 0:
        return 'rdc';
      case 1:
        return '1er';
      case 2:
        return '2eme';
      case 3:
        return '3eme';
      default:
        return 'rdc';
    }
  }

  /// Récupère les locaux disponibles pour les baux
  Future<List<Map<String, dynamic>>> getAvailableProperties() async {
    try {
      final response = await _supabase.from('locaux').select('''
            id,
            numero,
            statut,
            actif,
            etages!inner(nom, ordre),
            types_locaux!inner(nom, surface_m2)
          ''').eq('statut', 'Disponible').eq('actif', true).order('numero');

      print('✅ Récupération de ${response.length} locaux disponibles');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ ERREUR getAvailableProperties: $error');
      throw Exception('Erreur lors de la récupération des locaux: $error');
    }
  }

  /// Récupère tous les commerçants actifs
  Future<List<Map<String, dynamic>>> getActiveMerchants() async {
    try {
      final response = await _supabase
          .from('commercants')
          .select('id, nom, activite, contact, email, photo_url')
          .eq('actif', true)
          .order('nom');

      print('✅ Récupération de ${response.length} commerçants actifs');
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      print('❌ ERREUR getActiveMerchants: $error');
      throw Exception('Erreur lors de la récupération des commerçants: $error');
    }
  }

  /// Génère le prochain numéro de contrat
  Future<String> generateContractNumber() async {
    try {
      final year = DateTime.now().year;

      // Compte les baux de cette année
      final response = await _supabase
          .from('baux')
          .select('numero_contrat')
          .like('numero_contrat', 'BL-$year-%')
          .order('created_at', ascending: false)
          .limit(1);

      int nextNumber = 1;

      if (response.isNotEmpty) {
        final lastContract = response[0]['numero_contrat'] as String;
        // Extrait le dernier numéro (ex: BL-2025-003 → 3)
        final parts = lastContract.split('-');
        if (parts.length == 3) {
          nextNumber = (int.tryParse(parts[2]) ?? 0) + 1;
        }
      }

      // Format: BL-2025-001
      final contractNumber =
          'BL-$year-${nextNumber.toString().padLeft(3, '0')}';

      print('🔢 Numéro contrat généré: $contractNumber');
      return contractNumber;
    } catch (error) {
      print('❌ ERREUR generateContractNumber: $error');
      // En cas d'erreur, génère un numéro avec timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'BL-${DateTime.now().year}-$timestamp';
    }
  }

  /// Crée un nouveau bail
  Future<Map<String, dynamic>> createLease({
    required String contractNumber,
    required String propertyId,
    required String merchantId,
    required DateTime startDate,
    required DateTime endDate,
    required double monthlyRent,
    double? montantCaution,
    double? montantPasDePorte,
  }) async {
    try {
      print('🚀 Création bail: $contractNumber pour local $propertyId');

      // 1. Vérifie que le local est disponible
      final propertyResponse = await _supabase
          .from('locaux')
          .select('statut, numero')
          .eq('id', propertyId)
          .single();

      if (propertyResponse['statut'] != 'Disponible') {
        throw Exception('Ce local n\'est pas disponible');
      }

      // 2. Prépare les données d'insertion SANS définir le statut
      final insertData = {
        'numero_contrat': contractNumber,
        'local_id': propertyId,
        'commercant_id': merchantId,
        'date_debut': startDate.toIso8601String().split('T')[0],
        'date_fin': endDate.toIso8601String().split('T')[0],
        'montant_loyer': monthlyRent,
        'actif': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Ajoute les montants de dépôt si spécifiés
      if (montantCaution != null) {
        insertData['montant_caution'] = montantCaution;
      }
      if (montantPasDePorte != null) {
        insertData['montant_pas_de_porte'] = montantPasDePorte;
      }

      // 3. Crée le bail - Le trigger calculera automatiquement le statut
      final leaseResponse =
          await _supabase.from('baux').insert(insertData).select('''
            *,
            commercants!inner(
              nom,
              activite,
              contact,
              email,
              photo_url
            ),
            locaux!inner(
              numero,
              etages!inner(nom, ordre),
              types_locaux!inner(nom, surface_m2)
            )
          ''').single();

      // 4. Met à jour le statut du local à "Occupé"
      await _supabase.from('locaux').update({
        'statut': 'Occupé',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', propertyId);

      // 5. Log des informations de création
      print('✅ Bail créé avec succès: $contractNumber');
      print('✅ Local ${propertyResponse['numero']} maintenant Occupé');

      if (montantCaution != null) {
        print('💰 Caution: ${montantCaution.toStringAsFixed(0)} FCFA');
      }
      if (montantPasDePorte != null) {
        print('🏪 Pas de porte: ${montantPasDePorte.toStringAsFixed(0)} FCFA');
      }

      return leaseResponse;
    } catch (error, stackTrace) {
      print('❌ ERREUR createLease: $error');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Récupère les détails complets d'un bail
  Future<Map<String, dynamic>> getBailDetails(String bailId) async {
    try {
      // ✅ VALIDATION: Vérifie si l'UUID du bail est valide
      if (!_isValidUUID(bailId)) {
        throw Exception('ID de bail invalide: $bailId');
      }

      // Infos bail complet
      final bail = await _supabase.from('baux').select('''
        *,
        locaux!inner(*, types_locaux(*), etages(*)),
        commercants(*)
      ''').eq('id', bailId).single();

      // Ses paiements
      final paiements = await _supabase
          .from('paiements')
          .select()
          .eq('bail_id', bailId)
          .order('date_paiement', ascending: false);

      // Calcule statistiques avec prise en compte des modifications de loyer
      final montantLoyerActuel =
          (bail['montant_loyer'] as num?)?.toDouble() ?? 0;
      final dateDebut = DateTime.parse(bail['date_debut']);
      final dateModification = DateTime.parse(bail['updated_at']);
      final now = DateTime.now();

      // Calcule le montant attendu en tenant compte des modifications
      double montantAttendu = 0;
      final totalPaye =
          paiements.where((p) => p['statut'] == 'Payé').fold<double>(
                0,
                (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
              );

      // Logique améliorée pour le calcul du montant attendu
      // Si les paiements existants couvrent déjà une période, on les considère comme valides
      final paiementsPayes =
          paiements.where((p) => p['statut'] == 'Payé').toList();

      if (paiementsPayes.isNotEmpty) {
        // Utilise le nombre de paiements effectués multiplié par le loyer actuel
        // Cela évite les problèmes de recalcul quand le loyer change
        final nombrePaiementsEffectues = paiementsPayes.length;
        montantAttendu = montantLoyerActuel * nombrePaiementsEffectues;
      } else {
        // Calcul standard basé sur les mois écoulés
        int moisEcoules =
            (now.year - dateDebut.year) * 12 + now.month - dateDebut.month;
        if (moisEcoules < 0) moisEcoules = 0;
        montantAttendu = montantLoyerActuel * moisEcoules;
      }

      // Si le total payé dépasse le montant attendu, ajuste le montant attendu
      if (totalPaye > montantAttendu) {
        montantAttendu = totalPaye;
      }

      final enRetard =
          paiements.where((p) => p['statut'] == 'En retard').fold<double>(
                0,
                (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
              );

      // Calcul du taux de paiement avec logique améliorée
      double tauxPaiement = 0.0;
      if (montantAttendu > 0) {
        tauxPaiement = (totalPaye / montantAttendu * 100).clamp(0, 100);
      } else if (paiementsPayes.isNotEmpty) {
        // Si pas de montant attendu mais des paiements, considère comme 100%
        tauxPaiement = 100.0;
      }

      final paiementsPayesCount =
          paiements.where((p) => p['statut'] == 'Payé').length;
      final paiementsEnRetard =
          paiements.where((p) => p['statut'] == 'En retard').length;

      // Calcul des mois écoulés depuis le début
      int moisEcoules =
          (now.year - dateDebut.year) * 12 + now.month - dateDebut.month;
      if (moisEcoules < 0) moisEcoules = 0;

      return {
        'bail': bail,
        'paiements': paiements,
        'stats': {
          'montant_attendu': montantAttendu,
          'total_paye': totalPaye,
          'en_retard': enRetard,
          'taux_paiement': tauxPaiement,
          'paiements_payes': paiementsPayesCount,
          'paiements_en_retard': paiementsEnRetard,
          'mois_ecoules': moisEcoules,
        },
      };
    } catch (e) {
      print('❌ ERREUR getBailDetails: $e');
      rethrow;
    }
  }

  /// Met à jour un bail
  Future<Map<String, dynamic>> updateBail({
    required String bailId,
    required String dateDebut,
    required String dateFin,
    required double montantLoyer,
    required double caution,
    required double pasDePorte,
  }) async {
    try {
      // ✅ IMPORTANT: NE PAS mettre à jour le champ 'statut'
      // Le trigger Supabase le calculera automatiquement lors de l'UPDATE
      final response = await _supabase
          .from('baux')
          .update({
            'date_debut': dateDebut,
            'date_fin': dateFin,
            'montant_loyer': montantLoyer,
            'montant_caution': caution,
            'montant_pas_de_porte': pasDePorte,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bailId)
          .select('''
            *,
            locaux!inner(*, types_locaux(*), etages(*)),
            commercants(*)
          ''')
          .single();

      print(
          '✅ Bail $bailId mis à jour avec succès - Statut recalculé automatiquement');
      return response;
    } catch (e) {
      print('❌ ERREUR updateBail: $e');
      rethrow;
    }
  }

  /// Résilie un bail (met local en Disponible)
  Future<Map<String, dynamic>> resilierBail(String bailId) async {
    try {
      // Récupère le bail
      final bail = await _supabase
          .from('baux')
          .select('local_id')
          .eq('id', bailId)
          .single();

      final localId = bail['local_id'];

      // Met à jour le bail en "Résilié"
      await _supabase.from('baux').update({
        'statut': 'Résilié',
        'date_fin': DateTime.now().toIso8601String().split('T')[0],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bailId);

      // Met le local en "Disponible"
      await _supabase.from('locaux').update({
        'statut': 'Disponible',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', localId);

      print('✅ Bail $bailId résilié et local $localId libéré');
      return {'success': true};
    } catch (e) {
      print('❌ ERREUR resilierBail: $e');
      rethrow;
    }
  }
}
