import 'package:supabase_flutter/supabase_flutter.dart';

class LeasesService {
  static final LeasesService _instance = LeasesService._internal();
  factory LeasesService() => _instance;
  LeasesService._internal();

  final _supabase = Supabase.instance.client;

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

  /// Récupère les baux par statut
  Future<List<Map<String, dynamic>>> getLeasesByStatus(String status) async {
    try {
      String supabaseStatus = _getSupabaseStatus(status);

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
      ''')
          .eq('actif', true)
          .eq('statut', supabaseStatus)
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

      return leases;
    } catch (error) {
      print('❌ ERREUR getLeasesByStatus: $error');
      throw Exception('Erreur lors du filtrage par statut: $error');
    }
  }

  /// Met à jour le statut d'un bail
  Future<void> updateLeaseStatus(String leaseId, String newStatus) async {
    try {
      String supabaseStatus = _getSupabaseStatus(newStatus);

      await _supabase
          .from('baux')
          .update({'statut': supabaseStatus}).eq('id', leaseId);

      print('✅ Statut du bail $leaseId mis à jour vers $supabaseStatus');
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

    if (statut == 'Expiré') return 'high';

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
    String status = 'Actif',
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

      // 2. Prépare les données d'insertion
      final insertData = {
        'numero_contrat': contractNumber,
        'local_id': propertyId,
        'commercant_id': merchantId,
        'date_debut': startDate.toIso8601String().split('T')[0],
        'date_fin': endDate.toIso8601String().split('T')[0],
        'montant_loyer': monthlyRent,
        'statut': status,
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

      // 3. Crée le bail dans une transaction
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
}
