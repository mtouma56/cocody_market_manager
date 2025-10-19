import 'package:supabase_flutter/supabase_flutter.dart';

class MerchantsService {
  static final MerchantsService _instance = MerchantsService._internal();
  factory MerchantsService() => _instance;
  MerchantsService._internal();

  final _supabase = Supabase.instance.client;

  /// Récupère tous les commerçants avec leurs informations de bail
  Future<List<Map<String, dynamic>>> getAllMerchants() async {
    try {
      final response = await _supabase.from('commercants').select('''
        id,
        nom,
        activite,
        contact,
        email,
        photo_url,
        actif,
        created_at,
        baux(
          id,
          statut,
          date_debut,
          date_fin,
          montant_loyer,
          numero_contrat,
          locaux!inner(
            numero,
            etages!inner(nom, ordre),
            types_locaux!inner(nom)
          )
        )
      ''').eq('actif', true).order('nom');

      List<Map<String, dynamic>> merchants = [];

      for (var commercant in response) {
        // Déterminer le statut du commerçant basé sur ses baux
        String status = _determineStatus(commercant['baux']);
        Map<String, dynamic>? propertyInfo;

        // Récupérer les informations du local s'il y a un bail actif
        if (commercant['baux'] != null && commercant['baux'].isNotEmpty) {
          final bailActif = (commercant['baux'] as List).firstWhere(
            (bail) => bail['statut'] == 'Actif',
            orElse: () => commercant['baux'][0],
          );

          if (bailActif != null && bailActif['locaux'] != null) {
            final local = bailActif['locaux'];
            propertyInfo = {
              'number': local['numero'],
              'type':
                  _getPropertyTypeFromSupabase(local['types_locaux']['nom']),
              'floor': _getFloorName(local['etages']['ordre']),
            };
          }
        }

        merchants.add({
          'id': commercant['id'],
          'name': commercant['nom'],
          'businessType': commercant['activite'],
          'phone': commercant['contact'] ?? '',
          'email': commercant['email'] ?? '',
          'address': 'Cocody, Abidjan', // Address par défaut
          'status': status,
          'profilePhoto': commercant['photo_url'] ??
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
          'profilePhotoSemanticLabel':
              'Portrait professionnel de ${commercant['nom']}, commerçant au Marché Cocody',
          'notes': _generateNotes(commercant, status),
          'createdAt': commercant['created_at'],
          if (propertyInfo != null) ...propertyInfo,
        });
      }

      print(
          '✅ Récupération de ${merchants.length} commerçants depuis Supabase');
      return merchants;
    } catch (error) {
      print('❌ ERREUR getAllMerchants: $error');
      throw Exception('Erreur lors de la récupération des commerçants: $error');
    }
  }

  /// Récupère les commerçants par statut
  Future<List<Map<String, dynamic>>> getMerchantsByStatus(String status) async {
    try {
      final allMerchants = await getAllMerchants();
      return allMerchants
          .where((merchant) => merchant['status'] == status)
          .toList();
    } catch (error) {
      print('❌ ERREUR getMerchantsByStatus: $error');
      throw Exception('Erreur lors du filtrage par statut: $error');
    }
  }

  /// Ajoute un nouveau commerçant
  Future<Map<String, dynamic>> addMerchant(
      Map<String, dynamic> merchantData) async {
    try {
      final response = await _supabase
          .from('commercants')
          .insert({
            'nom': merchantData['name'],
            'activite': merchantData['businessType'],
            'contact': merchantData['phone'],
            'email': merchantData['email'],
            'photo_url': merchantData['profilePhoto'],
          })
          .select()
          .single();

      print('✅ Nouveau commerçant créé: ${response['nom']}');
      return response;
    } catch (error) {
      print('❌ ERREUR addMerchant: $error');
      throw Exception('Erreur lors de l\'ajout du commerçant: $error');
    }
  }

  /// Met à jour les informations d'un commerçant
  Future<void> updateMerchant(
      String merchantId, Map<String, dynamic> updates) async {
    try {
      await _supabase.from('commercants').update({
        if (updates['name'] != null) 'nom': updates['name'],
        if (updates['businessType'] != null)
          'activite': updates['businessType'],
        if (updates['phone'] != null) 'contact': updates['phone'],
        if (updates['email'] != null) 'email': updates['email'],
        if (updates['profilePhoto'] != null)
          'photo_url': updates['profilePhoto'],
      }).eq('id', merchantId);

      print('✅ Commerçant $merchantId mis à jour');
    } catch (error) {
      print('❌ ERREUR updateMerchant: $error');
      throw Exception('Erreur lors de la mise à jour: $error');
    }
  }

  /// Supprime un commerçant (désactivation)
  Future<void> removeMerchant(String merchantId) async {
    try {
      await _supabase
          .from('commercants')
          .update({'actif': false}).eq('id', merchantId);
      print('✅ Commerçant $merchantId désactivé');
    } catch (error) {
      print('❌ ERREUR removeMerchant: $error');
      throw Exception('Erreur lors de la suppression: $error');
    }
  }

  /// Détermine le statut du commerçant basé sur ses baux
  String _determineStatus(List<dynamic>? baux) {
    if (baux == null || baux.isEmpty) {
      return 'inactive'; // Pas de bail
    }

    // Vérifier si il y a un bail actif
    bool hasActiveLease = baux.any((bail) => bail['statut'] == 'Actif');
    if (hasActiveLease) return 'active';

    // Vérifier si il y a un bail qui expire bientôt
    bool hasExpiringLease =
        baux.any((bail) => bail['statut'] == 'Expire bientôt');
    if (hasExpiringLease) return 'expiring';

    // Sinon, statut basé sur le dernier bail
    return 'overdue';
  }

  /// Convertit le nom du type de local de Supabase en code
  String _getPropertyTypeFromSupabase(String typeName) {
    switch (typeName) {
      case 'Boutique 9m²':
        return 'shop';
      case 'Boutique 4.5m²':
        return 'shop';
      case 'Restaurant':
        return 'restaurant';
      case 'Banque':
        return 'bank';
      case 'Box':
        return 'box';
      case 'Étal':
        return 'market_stall';
      default:
        return 'shop';
    }
  }

  /// Convertit l'ordre d'étage en nom d'étage
  String _getFloorName(int ordre) {
    switch (ordre) {
      case 0:
        return 'Rez-de-chaussée';
      case 1:
        return '1er étage';
      case 2:
        return '2ème étage';
      case 3:
        return '3ème étage';
      default:
        return 'Rez-de-chaussée';
    }
  }

  /// Génère des notes automatiques pour le commerçant
  String _generateNotes(Map<String, dynamic> commercant, String status) {
    switch (status) {
      case 'active':
        return 'Commerçant actif avec bail en cours';
      case 'expiring':
        return 'Bail expire bientôt - Renouvellement à prévoir';
      case 'overdue':
        return 'Problème de paiement ou bail expiré - À contacter';
      default:
        return 'Nouveau commerçant inscrit';
    }
  }
}
