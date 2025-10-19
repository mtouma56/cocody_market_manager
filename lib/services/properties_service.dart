import 'package:supabase_flutter/supabase_flutter.dart';

class PropertiesService {
  static final PropertiesService _instance = PropertiesService._internal();
  factory PropertiesService() => _instance;
  PropertiesService._internal();

  final _supabase = Supabase.instance.client;

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
        String typeCode = _getTypeCode(local['types_locaux']['nom']);

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
        String typeCode = _getTypeCode(local['types_locaux']['nom']);

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
  String _getFloorCode(int ordre) {
    switch (ordre) {
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

  /// Convertit le nom du type en code type
  String _getTypeCode(String typeName) {
    switch (typeName) {
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

  /// Convertit le statut Supabase en code statut
  String _getStatusCode(String supabaseStatus) {
    switch (supabaseStatus) {
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

  /// Convertit le code statut en statut Supabase
  String _getSupabaseStatus(String statusCode) {
    switch (statusCode) {
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
}
