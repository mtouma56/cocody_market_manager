import 'package:supabase_flutter/supabase_flutter.dart';

class PropertiesService {
  static final PropertiesService _instance = PropertiesService._internal();
  factory PropertiesService() => _instance;
  PropertiesService._internal();

  final _supabase = Supabase.instance.client;

  /// Crée un nouveau local dans Supabase
  Future<Map<String, dynamic>> createLocal({
    required String numero,
    required String typeId,
    required String etageId,
    String statut = 'Disponible',
    bool actif = true,
  }) async {
    try {
      print(
          '🚀 Création local: numero=$numero, type=$typeId, etage=$etageId, statut=$statut');

      // INSERT dans Supabase
      final response = await _supabase.from('locaux').insert({
        'numero': numero,
        'type_id': typeId,
        'etage_id': etageId,
        'statut': statut,
        'actif': actif,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select('''
            *,
            types_locaux(*),
            etages(*)
          ''').single();

      print('✅ Local créé avec succès: ${response['numero']}');

      return response;
    } catch (e, stackTrace) {
      print('❌ ERREUR createLocal: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Important : relance l'erreur pour que l'UI la capture
    }
  }

  /// Met à jour un local existant
  Future<Map<String, dynamic>> updateLocal({
    required String id,
    String? numero,
    String? typeId,
    String? etageId,
    String? statut,
    bool? actif,
  }) async {
    try {
      print('🔄 Mise à jour local: id=$id');

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (numero != null) data['numero'] = numero;
      if (typeId != null) data['type_id'] = typeId;
      if (etageId != null) data['etage_id'] = etageId;
      if (statut != null) data['statut'] = statut;
      if (actif != null) data['actif'] = actif;

      final response =
          await _supabase.from('locaux').update(data).eq('id', id).select('''
            *,
            types_locaux(*),
            etages(*)
          ''').single();

      print('✅ Local mis à jour avec succès');

      return response;
    } catch (e, stackTrace) {
      print('❌ ERREUR updateLocal: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Supprime un local
  Future<void> deleteLocal(String id) async {
    try {
      print('🗑️ Suppression local: id=$id');

      await _supabase.from('locaux').delete().eq('id', id);

      print('✅ Local supprimé avec succès');
    } catch (e, stackTrace) {
      print('❌ ERREUR deleteLocal: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Récupère les types de locaux disponibles
  Future<List<Map<String, dynamic>>> getPropertyTypes() async {
    try {
      final response = await _supabase
          .from('types_locaux')
          .select('*')
          .eq('actif', true)
          .order('nom');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ERREUR getPropertyTypes: $e');
      throw Exception('Erreur lors de la récupération des types: $e');
    }
  }

  /// Récupère les étages disponibles
  Future<List<Map<String, dynamic>>> getFloors() async {
    try {
      final response = await _supabase
          .from('etages')
          .select('*')
          .eq('actif', true)
          .order('ordre');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ ERREUR getFloors: $e');
      throw Exception('Erreur lors de la récupération des étages: $e');
    }
  }

  /// Récupère tous les locaux avec leurs informations complètes
  Future<List<Map<String, dynamic>>> getAllProperties() async {
    try {
      final response = await _supabase.from('locaux').select('''
        id,
        numero,
        statut,
        actif,
        etages!inner(nom, ordre),
        types_locaux!inner(nom, surface_m2),
        baux(
          id,
          statut,
          commercants!inner(nom, activite, contact)
        )
      ''').eq('actif', true).order('numero');

      List<Map<String, dynamic>> properties = [];

      for (var local in response) {
        // Déterminer l'étage en format court
        String floorCode = _getFloorCode(local['etages']['ordre']);

        // Déterminer le type en format code
        String typeCode = _getPropertyTypeCode(local['types_locaux']['nom']);

        // Préparer les données du locataire s'il y en a un
        Map<String, dynamic>? tenant;
        if (local['baux'] != null && local['baux'].isNotEmpty) {
          final bail = local['baux'][0];
          if (bail['statut'] == 'Actif' && bail['commercants'] != null) {
            tenant = {
              'name': bail['commercants']['nom'],
              'business': bail['commercants']['activite'],
              'phone': bail['commercants']['contact'],
            };
          }
        }

        properties.add({
          'id': local['id'],
          'number': local['numero'],
          'floor': floorCode,
          'type': typeCode,
          'size': '${local['types_locaux']['surface_m2']}m²',
          'status': _getStatusCode(local['statut']),
          if (tenant != null) 'tenant': tenant,
        });
      }

      return properties;
    } catch (error) {
      print('❌ ERREUR getAllProperties: $error');
      throw Exception('Erreur lors de la récupération des locaux: $error');
    }
  }

  /// Récupère les locaux par étage
  Future<List<Map<String, dynamic>>> getPropertiesByFloor(
      String floorCode) async {
    try {
      int ordre = _getFloorOrder(floorCode);

      final response = await _supabase.from('locaux').select('''
        id,
        numero,
        statut,
        actif,
        etages!inner(nom, ordre),
        types_locaux!inner(nom, surface_m2),
        baux(
          id,
          statut,
          commercants!inner(nom, activite, contact)
        )
      ''').eq('actif', true).eq('etages.ordre', ordre).order('numero');

      List<Map<String, dynamic>> properties = [];

      for (var local in response) {
        String typeCode = _getPropertyTypeCode(local['types_locaux']['nom']);

        Map<String, dynamic>? tenant;
        if (local['baux'] != null && local['baux'].isNotEmpty) {
          final bail = local['baux'][0];
          if (bail['statut'] == 'Actif' && bail['commercants'] != null) {
            tenant = {
              'name': bail['commercants']['nom'],
              'business': bail['commercants']['activite'],
              'phone': bail['commercants']['contact'],
            };
          }
        }

        properties.add({
          'id': local['id'],
          'number': local['numero'],
          'floor': floorCode,
          'type': typeCode,
          'size': '${local['types_locaux']['surface_m2']}m²',
          'status': _getStatusCode(local['statut']),
          if (tenant != null) 'tenant': tenant,
        });
      }

      return properties;
    } catch (error) {
      print('❌ ERREUR getPropertiesByFloor: $error');
      throw Exception(
          'Erreur lors de la récupération des locaux par étage: $error');
    }
  }

  /// Met à jour le statut d'un local
  Future<void> updatePropertyStatus(String propertyId, String newStatus) async {
    try {
      String supabaseStatus = _getSupabaseStatus(newStatus);

      await _supabase
          .from('locaux')
          .update({'statut': supabaseStatus}).eq('id', propertyId);

      print('✅ Statut du local $propertyId mis à jour vers $supabaseStatus');
    } catch (error) {
      print('❌ ERREUR updatePropertyStatus: $error');
      throw Exception('Erreur lors de la mise à jour du statut: $error');
    }
  }

  /// Convertit l'ordre d'étage en code court
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

  /// Convertit le code d'étage en ordre
  int _getFloorOrder(String floorCode) {
    switch (floorCode) {
      case 'rdc':
        return 0;
      case '1er':
        return 1;
      case '2eme':
        return 2;
      case '3eme':
        return 3;
      default:
        return 0;
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

  /// Convertit le statut Supabase en code
  String _getStatusCode(String? supabaseStatus) {
    final safeStatus = supabaseStatus ?? '';
    switch (safeStatus) {
      case 'Occupé':
        return 'occupied';
      case 'Disponible':
        return 'available';
      case 'Maintenance':
        return 'maintenance';
      default:
        return 'available';
    }
  }

  /// Convertit le code de statut en statut Supabase
  String _getSupabaseStatus(String? statusCode) {
    final safeStatusCode = statusCode ?? '';
    switch (safeStatusCode) {
      case 'occupied':
        return 'Occupé';
      case 'available':
        return 'Disponible';
      case 'maintenance':
        return 'Maintenance';
      default:
        return 'Disponible';
    }
  }

  /// Génère une description automatique pour le local
  String _generateDescription(String? typeNom, String? etageNom) {
    final safeType = typeNom ?? 'Local';
    final safeEtage = etageNom ?? 'Rez-de-chaussée';
    return '$safeType situé au $safeEtage du Marché Cocody Saint-Jean';
  }

  /// Récupère les détails complets d'un local
  Future<Map<String, dynamic>> getPropertyDetails(String localId) async {
    try {
      print('🔍 Récupération détails local: id=$localId');

      // Récupère les informations du local avec toutes les relations
      final local = await _supabase.from('locaux').select('''
            *,
            types_locaux(*),
            etages(*),
            baux(
              *,
              commercants(*)
            )
          ''').eq('id', localId).single();

      // Récupère l'historique des paiements pour ce local
      final paiements = await _supabase
          .from('paiements')
          .select('''
            *,
            baux!inner(
              commercant_id,
              locaux!inner(id)
            )
          ''')
          .eq('baux.locaux.id', localId)
          .order('date_paiement', ascending: false);

      // Calcule les statistiques
      final totalPaiements = paiements.length;
      final paiementsPayes =
          paiements.where((p) => p['statut'] == 'Payé').length;
      final montantTotal = paiements
          .where((p) => p['statut'] == 'Payé')
          .fold<double>(
              0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));

      final paiementsEnRetard =
          paiements.where((p) => p['statut'] == 'En retard').length;
      final montantEnRetard = paiements
          .where((p) => p['statut'] == 'En retard')
          .fold<double>(
              0, (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0));

      // Récupère le bail actif s'il existe
      final bailActif = (local['baux'] as List?)?.firstWhere(
        (b) => b['statut'] == 'Actif',
        orElse: () => null,
      );

      print('✅ Détails local récupérés avec succès');

      return {
        'local': local,
        'bail_actif': bailActif,
        'paiements': paiements.take(20).toList(), // Limité aux 20 derniers
        'stats': {
          'total_paiements': totalPaiements,
          'paiements_payes': paiementsPayes,
          'montant_total': montantTotal,
          'paiements_en_retard': paiementsEnRetard,
          'montant_en_retard': montantEnRetard,
          'taux_paiement': totalPaiements > 0
              ? (paiementsPayes / totalPaiements * 100)
              : 0.0,
        },
      };
    } catch (e, stackTrace) {
      print('❌ ERREUR getPropertyDetails: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
