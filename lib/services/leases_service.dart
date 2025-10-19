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
}
