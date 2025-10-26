import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

import './cache_service.dart';
import './connectivity_service.dart';
import './storage_service.dart';

class MerchantsService {
  static final MerchantsService _instance = MerchantsService._internal();
  factory MerchantsService() => _instance;
  MerchantsService._internal();

  final _supabase = Supabase.instance.client;
  final _connectivity = ConnectivityService();
  final _cache = CacheService();
  final _storage = StorageService();

  /// Récupère tous les commerçants avec leurs informations de bail
  Future<List<Map<String, dynamic>>> getAllMerchants() async {
    // Si en ligne, récupérer depuis Supabase et mettre en cache
    if (_connectivity.isOnline) {
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
                'type': _getPropertyTypeFromSupabase(
                  local['types_locaux']['nom'],
                ),
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

        // Mettre à jour le cache
        await _cache.cacheCommercants(merchants);

        print(
          '✅ Récupération de ${merchants.length} commerçants depuis Supabase',
        );
        return merchants;
      } catch (error) {
        print('❌ ERREUR getAllMerchants Supabase, utilisation cache: $error');
        // Si erreur, utiliser le cache
        return _cache.getCommercants().cast<Map<String, dynamic>>();
      }
    }

    // Si hors ligne, utiliser le cache
    print('📡 Mode hors ligne - données commerçants en cache');
    return _cache.getCommercants().cast<Map<String, dynamic>>();
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
    Map<String, dynamic> merchantData,
  ) async {
    if (!_connectivity.isOnline) {
      throw Exception(
          'Action impossible hors ligne. Connectez-vous pour créer un commerçant.');
    }

    try {
      // Préparer les données en gérant les champs optionnels
      final Map<String, dynamic> insertData = {
        'nom': merchantData['name'],
        'activite': merchantData['businessType'],
        'contact': merchantData['phone'],
      };

      // Ajouter l'email seulement s'il n'est pas vide
      final email = merchantData['email']?.toString().trim();
      if (email != null && email.isNotEmpty) {
        insertData['email'] = email;
      }

      // Ajouter l'adresse seulement si elle n'est pas vide
      final address = merchantData['address']?.toString().trim();
      if (address != null && address.isNotEmpty) {
        insertData['adresse'] = address;
      }

      // Ajouter la photo si fournie
      if (merchantData['profilePhoto'] != null) {
        insertData['photo_url'] = merchantData['profilePhoto'];
      }

      final response = await _supabase
          .from('commercants')
          .insert(insertData)
          .select()
          .single();

      print('✅ Nouveau commerçant créé: ${response['nom']}');
      return response;
    } catch (error) {
      print('❌ ERREUR addMerchant: $error');

      // Fournir des messages d'erreur plus spécifiques
      if (error.toString().contains('commercants_email_unique_when_present')) {
        throw Exception(
          'Cette adresse email est déjà utilisée par un autre commerçant',
        );
      } else if (error.toString().contains('not-null constraint')) {
        throw Exception('Veuillez remplir tous les champs obligatoires');
      }

      throw Exception('Erreur lors de l\'ajout du commerçant: $error');
    }
  }

  /// Met à jour un commerçant
  Future<Map<String, dynamic>> updateCommercant({
    required String commercantId,
    required String nom,
    required String activite,
    required String contact,
    String? email,
    String? photoUrl,
  }) async {
    if (!_connectivity.isOnline) {
      throw Exception(
          'Action impossible hors ligne. Connectez-vous pour modifier un commerçant.');
    }

    try {
      final response = await _supabase
          .from('commercants')
          .update({
            'nom': nom,
            'activite': activite,
            'contact': contact,
            'email': email,
            'photo_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commercantId)
          .select()
          .single();

      return response;
    } catch (e) {
      print('❌ ERREUR updateCommercant: $e');
      rethrow;
    }
  }

  /// Upload et met à jour la photo de profil d'un commerçant
  Future<Map<String, dynamic>?> uploadMerchantProfilePhoto({
    required String commercantId,
    required XFile imageFile,
  }) async {
    if (!_connectivity.isOnline) {
      throw Exception(
          'Action impossible hors ligne. Connectez-vous pour uploader une photo.');
    }

    try {
      print('📤 Upload photo profil pour commerçant: $commercantId');

      // 1. Upload la photo vers Supabase Storage
      final uploadResult = await _storage.uploadMerchantProfilePhoto(
        file: imageFile,
        merchantId: commercantId,
      );

      if (uploadResult == null || uploadResult['success'] != true) {
        throw Exception(uploadResult?['error'] ?? 'Erreur lors de l\'upload');
      }

      final photoUrl = uploadResult['public_url'];

      // 2. Mettre à jour l'URL dans la base de données
      final response = await _supabase
          .from('commercants')
          .update({
            'photo_url': photoUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commercantId)
          .select()
          .single();

      print('✅ Photo de profil mise à jour pour ${response['nom']}');

      return {
        'success': true,
        'photo_url': photoUrl,
        'commercant': response,
      };
    } catch (e) {
      print('❌ ERREUR uploadMerchantProfilePhoto: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Sélectionne et upload photo depuis la galerie
  Future<Map<String, dynamic>?> pickAndUploadFromGallery(
      String commercantId) async {
    try {
      final imageFile = await _storage.pickImageFromGallery();
      if (imageFile == null) {
        return {'success': false, 'error': 'Aucune image sélectionnée'};
      }

      return await uploadMerchantProfilePhoto(
        commercantId: commercantId,
        imageFile: imageFile,
      );
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Prend et upload photo depuis la caméra
  Future<Map<String, dynamic>?> pickAndUploadFromCamera(
      String commercantId) async {
    try {
      final imageFile = await _storage.pickImageFromCamera();
      if (imageFile == null) {
        return {'success': false, 'error': 'Aucune photo prise'};
      }

      return await uploadMerchantProfilePhoto(
        commercantId: commercantId,
        imageFile: imageFile,
      );
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Supprime un commerçant (désactivation)
  Future<void> removeMerchant(String merchantId) async {
    if (!_connectivity.isOnline) {
      throw Exception(
          'Action impossible hors ligne. Connectez-vous pour supprimer un commerçant.');
    }

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
    bool hasActiveLease = baux.any((bail) => bail?['statut'] == 'Actif');
    if (hasActiveLease) return 'active';

    // Vérifier si il y a un bail qui expire bientôt
    bool hasExpiringLease = baux.any(
      (bail) => bail?['statut'] == 'Expire bientôt',
    );
    if (hasExpiringLease) return 'expiring';

    // Sinon, statut basé sur le dernier bail
    return 'overdue';
  }

  /// Convertit le nom du type de local de Supabase en code
  String _getPropertyTypeFromSupabase(String? typeName) {
    final safeTypeName = typeName ?? '';
    switch (safeTypeName) {
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
  String _getFloorName(int? ordre) {
    final safeOrdre = ordre ?? 0;
    switch (safeOrdre) {
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
  String _generateNotes(Map<String, dynamic>? commercant, String status) {
    if (commercant == null) return 'Données commercant non disponibles';

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

  /// Récupère détails complets d'un commerçant
  Future<Map<String, dynamic>> getCommercantDetails(String commercantId) async {
    if (!_connectivity.isOnline) {
      throw Exception('Cette fonctionnalité nécessite une connexion internet.');
    }

    try {
      // Infos commerçant
      final commercant = await _supabase
          .from('commercants')
          .select()
          .eq('id', commercantId)
          .single();

      // Ses baux (actifs et passés)
      final baux = await _supabase
          .from('baux')
          .select('''
        *,
        locaux!inner(*, types_locaux(*), etages(*))
      ''')
          .eq('commercant_id', commercantId)
          .order('date_debut', ascending: false);

      // Ses paiements
      final paiements = await _supabase
          .from('paiements')
          .select('''
        *,
        baux!inner(
          *,
          locaux!inner(*, types_locaux(*), etages(*))
        )
      ''')
          .eq('baux.commercant_id', commercantId)
          .order('date_paiement', ascending: false);

      // Calcule statistiques
      final totalPaye =
          paiements.where((p) => p['statut'] == 'Payé').fold<double>(
                0,
                (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
              );

      final enRetard =
          paiements.where((p) => p['statut'] == 'En retard').fold<double>(
                0,
                (sum, p) => sum + ((p['montant'] as num?)?.toDouble() ?? 0),
              );

      final bauxActifs = baux.where((b) => b['statut'] == 'Actif').length;

      return {
        'commercant': commercant,
        'baux': baux,
        'paiements': paiements,
        'stats': {
          'total_paye': totalPaye,
          'en_retard': enRetard,
          'baux_actifs': bauxActifs,
          'total_baux': baux.length,
        },
      };
    } catch (e) {
      print('❌ ERREUR getCommercantDetails: $e');
      rethrow;
    }
  }

  /// Recherche commerçants par nom OU numéro de local
  Future<List<Map<String, dynamic>>> searchCommercants(String query) async {
    // Utiliser le cache si hors ligne
    if (!_connectivity.isOnline) {
      print('🔍 Recherche hors ligne dans le cache');
      final cachedMerchants =
          _cache.getCommercants().cast<Map<String, dynamic>>();

      if (query.isEmpty) return cachedMerchants;

      return cachedMerchants.where((merchant) {
        final name = (merchant['name'] as String? ?? '').toLowerCase();
        final businessType =
            (merchant['businessType'] as String? ?? '').toLowerCase();
        final phone = (merchant['phone'] as String? ?? '').toLowerCase();
        final q = query.toLowerCase();

        return name.contains(q) ||
            businessType.contains(q) ||
            phone.contains(q);
      }).toList();
    }

    try {
      if (query.isEmpty) {
        return await getAllMerchants();
      }

      // Recherche dans commercants ET dans locaux via baux
      final commercants = await _supabase.from('commercants').select('''
        *,
        baux!left(
          *,
          locaux!inner(*)
        )
      ''').order('nom');

      // Filtre par nom, activité, contact OU numéro de local
      final filtered = commercants.where((c) {
        final nom = (c['nom'] as String? ?? '').toLowerCase();
        final activite = (c['activite'] as String? ?? '').toLowerCase();
        final contact = (c['contact'] as String? ?? '').toLowerCase();
        final q = query.toLowerCase();

        // Recherche dans nom/activite/contact
        if (nom.contains(q) || activite.contains(q) || contact.contains(q)) {
          return true;
        }

        // Recherche dans numéros de locaux
        final baux = c['baux'] as List?;
        if (baux != null) {
          for (var bail in baux) {
            final local = bail?['locaux'];
            if (local != null) {
              final numero = (local['numero'] as String? ?? '').toLowerCase();
              if (numero.contains(q)) {
                return true;
              }
            }
          }
        }

        return false;
      }).toList();

      print('🔍 Recherche "$query": ${filtered.length} résultats');

      // Transform the data to match the expected format
      List<Map<String, dynamic>> merchants = [];

      for (var commercant in filtered) {
        // Déterminer le statut du commerçant basé sur ses baux
        String status = _determineStatus(commercant['baux']);
        Map<String, dynamic>? propertyInfo;

        // Récupérer les informations du local s'il y a un bail actif
        if (commercant['baux'] != null &&
            (commercant['baux'] as List).isNotEmpty) {
          final baux = commercant['baux'] as List;
          final bailActif = baux.firstWhere(
            (bail) => bail?['statut'] == 'Actif',
            orElse: () => baux.isNotEmpty ? baux[0] : null,
          );

          if (bailActif != null && bailActif['locaux'] != null) {
            final local = bailActif['locaux'];
            propertyInfo = {
              'number': local['numero'] ?? '',
              'type': _getPropertyTypeFromSupabase(
                local['types_locaux']?['nom'],
              ),
              'floor': _getFloorName(local['etages']?['ordre']),
            };
          }
        }

        merchants.add({
          'id': commercant['id'],
          'name': commercant['nom'] ?? '',
          'businessType': commercant['activite'] ?? '',
          'phone': commercant['contact'] ?? '',
          'email': commercant['email'] ?? '',
          'address': 'Cocody, Abidjan', // Address par défaut
          'status': status,
          'profilePhoto': commercant['photo_url'] ??
              'https://images.pexels.com/photos/1239291/pexels-photo-1239291.jpeg?auto=compress&cs=tinysrgb&w=400',
          'profilePhotoSemanticLabel':
              'Portrait professionnel de ${commercant['nom'] ?? 'Commerçant'}, commerçant au Marché Cocody',
          'notes': _generateNotes(commercant, status),
          'createdAt': commercant['created_at'],
          if (propertyInfo != null) ...propertyInfo,
        });
      }

      return merchants;
    } catch (e) {
      print('❌ ERREUR searchCommercants: $e');
      return [];
    }
  }
}
