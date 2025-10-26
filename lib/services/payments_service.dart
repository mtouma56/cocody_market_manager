import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentsService {
  static final PaymentsService _instance = PaymentsService._internal();
  factory PaymentsService() => _instance;
  PaymentsService._internal();

  final _supabase = Supabase.instance.client;

  /// Valide qu'une chaîne est un UUID valide
  bool _isValidUUID(String? uuid) {
    if (uuid == null || uuid.isEmpty) return false;
    final uuidRegExp = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegExp.hasMatch(uuid);
  }

  /// Récupère tous les paiements avec leurs informations complètes
  Future<List<Map<String, dynamic>>> getAllPayments() async {
    try {
      final response = await _supabase.from('paiements').select('''
        id,
        montant,
        date_paiement,
        date_echeance,
        mois_concerne,
        statut,
        mode_paiement,
        notes,
        created_at,
        baux!inner(
          id,
          numero_contrat,
          commercant_id,
          commercants!inner(nom, activite, contact),
          locaux!inner(
            numero,
            etages!inner(nom, ordre),
            types_locaux!inner(nom)
          )
        )
      ''').order('created_at', ascending: false);

      List<Map<String, dynamic>> payments = [];

      for (var paiement in response) {
        // Déterminer l'urgence basée sur le statut et les dates
        String urgency = _determineUrgency(
          paiement['statut'],
          paiement['date_echeance'],
          paiement['date_paiement'],
        );

        payments.add({
          'id': paiement['id'],
          'merchantId': paiement['baux']
              ['commercant_id'], // ✅ AJOUT: ID du commerçant
          'amount': (paiement['montant'] as num).toDouble(),
          'dueDate': paiement['date_echeance'],
          'paymentDate': paiement['date_paiement'],
          'monthConcerned': paiement['mois_concerne'],
          'status': _getStatusCode(paiement['statut']),
          'paymentMethod': _getPaymentMethodCode(paiement['mode_paiement']),
          'notes': paiement['notes'] ?? '',
          'urgency': urgency,
          'tenantName': paiement['baux']['commercants']['nom'],
          'tenantBusiness': paiement['baux']['commercants']['activite'],
          'tenantPhone': paiement['baux']['commercants']['contact'],
          'contractNumber': paiement['baux']['numero_contrat'],
          'propertyNumber': paiement['baux']['locaux']['numero'],
          'propertyType': _getPropertyTypeCode(
            paiement['baux']['locaux']['types_locaux']['nom'],
          ),
          'propertyFloor': _getFloorCode(
            paiement['baux']['locaux']['etages']['ordre'],
          ),
          'createdAt': paiement['created_at'],
        });
      }

      print('✅ Récupération de ${payments.length} paiements depuis Supabase');
      return payments;
    } catch (error) {
      print('❌ ERREUR getAllPayments: $error');
      throw Exception('Erreur lors de la récupération des paiements: $error');
    }
  }

  /// Récupère les paiements par commerçant (avec validation UUID)
  Future<List<Map<String, dynamic>>> getPaymentsByMerchant(
    String? merchantId,
  ) async {
    try {
      // ✅ VALIDATION: Vérifie si l'UUID du commerçant est valide
      if (!_isValidUUID(merchantId)) {
        print(
          '⚠️ UUID commerçant invalide: $merchantId - Retour de tous les paiements',
        );
        return await getAllPayments();
      }

      // ✅ FIX: Vérifier si le merchantId est null ou vide APRÈS la validation UUID
      if (merchantId == null || merchantId.isEmpty) {
        print('⚠️ MerchantId null ou vide - Retour de tous les paiements');
        return await getAllPayments();
      }

      final response = await _supabase
          .from('paiements')
          .select('''
        id,
        montant,
        date_paiement,
        date_echeance,
        mois_concerne,
        statut,
        mode_paiement,
        notes,
        created_at,
        baux!inner(
          id,
          numero_contrat,
          commercant_id,
          commercants!inner(nom, activite, contact),
          locaux!inner(
            numero,
            etages!inner(nom, ordre),
            types_locaux!inner(nom)
          )
        )
      ''')
          .eq(
            'baux.commercant_id',
            merchantId,
          ) // ✅ Maintenant sûr d'utiliser un UUID valide
          .order('created_at', ascending: false);

      List<Map<String, dynamic>> payments = [];

      for (var paiement in response) {
        String urgency = _determineUrgency(
          paiement['statut'],
          paiement['date_echeance'],
          paiement['date_paiement'],
        );

        payments.add({
          'id': paiement['id'],
          'merchantId': paiement['baux']
              ['commercant_id'], // ✅ AJOUT: ID du commerçant
          'amount': (paiement['montant'] as num).toDouble(),
          'dueDate': paiement['date_echeance'],
          'paymentDate': paiement['date_paiement'],
          'monthConcerned': paiement['mois_concerne'],
          'status': _getStatusCode(paiement['statut']),
          'paymentMethod': _getPaymentMethodCode(paiement['mode_paiement']),
          'notes': paiement['notes'] ?? '',
          'urgency': urgency,
          'tenantName': paiement['baux']['commercants']['nom'],
          'tenantBusiness': paiement['baux']['commercants']['activite'],
          'tenantPhone': paiement['baux']['commercants']['contact'],
          'contractNumber': paiement['baux']['numero_contrat'],
          'propertyNumber': paiement['baux']['locaux']['numero'],
          'propertyType': _getPropertyTypeCode(
            paiement['baux']['locaux']['types_locaux']['nom'],
          ),
          'propertyFloor': _getFloorCode(
            paiement['baux']['locaux']['etages']['ordre'],
          ),
          'createdAt': paiement['created_at'],
        });
      }

      print(
        '✅ Récupération de ${payments.length} paiements pour le commerçant $merchantId',
      );
      return payments;
    } catch (error) {
      print('❌ ERREUR getPaymentsByMerchant: $error');
      throw Exception('Erreur lors du filtrage par commerçant: $error');
    }
  }

  /// Récupère les paiements par statut
  Future<List<Map<String, dynamic>>> getPaymentsByStatus(String status) async {
    try {
      String supabaseStatus = _getSupabaseStatus(status);

      final response = await _supabase.from('paiements').select('''
        id,
        montant,
        date_paiement,
        date_echeance,
        mois_concerne,
        statut,
        mode_paiement,
        notes,
        created_at,
        baux!inner(
          id,
          numero_contrat,
          commercant_id,
          commercants!inner(nom, activite, contact),
          locaux!inner(
            numero,
            etages!inner(nom, ordre),
            types_locaux!inner(nom)
          )
        )
      ''').eq('statut', supabaseStatus).order('created_at', ascending: false);

      List<Map<String, dynamic>> payments = [];

      for (var paiement in response) {
        String urgency = _determineUrgency(
          paiement['statut'],
          paiement['date_echeance'],
          paiement['date_paiement'],
        );

        payments.add({
          'id': paiement['id'],
          'merchantId': paiement['baux']
              ['commercant_id'], // ✅ AJOUT: ID du commerçant
          'amount': (paiement['montant'] as num).toDouble(),
          'dueDate': paiement['date_echeance'],
          'paymentDate': paiement['date_paiement'],
          'monthConcerned': paiement['mois_concerne'],
          'status': _getStatusCode(paiement['statut']),
          'paymentMethod': _getPaymentMethodCode(paiement['mode_paiement']),
          'notes': paiement['notes'] ?? '',
          'urgency': urgency,
          'tenantName': paiement['baux']['commercants']['nom'],
          'tenantBusiness': paiement['baux']['commercants']['activite'],
          'tenantPhone': paiement['baux']['commercants']['contact'],
          'contractNumber': paiement['baux']['numero_contrat'],
          'propertyNumber': paiement['baux']['locaux']['numero'],
          'propertyType': _getPropertyTypeCode(
            paiement['baux']['locaux']['types_locaux']['nom'],
          ),
          'propertyFloor': _getFloorCode(
            paiement['baux']['locaux']['etages']['ordre'],
          ),
          'createdAt': paiement['created_at'],
        });
      }

      return payments;
    } catch (error) {
      print('❌ ERREUR getPaymentsByStatus: $error');
      throw Exception('Erreur lors du filtrage par statut: $error');
    }
  }

  /// Récupère les paiements en retard (FIXED: Suppression des colonnes inexistantes)
  Future<List<Map<String, dynamic>>> getOverduePayments() async {
    try {
      final response = await _supabase
          .from('paiements')
          .select('''
            id,
            montant,
            date_echeance,
            statut,
            mois_concerne,
            notes,
            baux!inner(
              id,
              numero_contrat,
              commercants!inner(
                id,
                nom,
                contact
              ),
              locaux!inner(
                id,
                numero
              )
            )
          ''')
          .eq('statut', 'En retard')
          .order('date_echeance', ascending: true);

      print('✅ Paiements en retard récupérés: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Erreur récupération paiements en retard: $e');
      throw Exception('Impossible de récupérer les paiements en retard: $e');
    }
  }

  /// Récupère les détails d'un paiement (avec validation UUID)
  Future<Map<String, dynamic>> getPaymentDetails(String paymentId) async {
    try {
      // ✅ VALIDATION: Vérifie si l'UUID du paiement est valide
      if (!_isValidUUID(paymentId)) {
        throw Exception('ID de paiement invalide: $paymentId');
      }

      final response = await _supabase.from('paiements').select('''
        *,
        baux!inner(
          *,
          commercants(*),
          locaux!inner(
            *,
            etages(*),
            types_locaux(*)
          )
        )
      ''').eq('id', paymentId).single();

      print('✅ Détails du paiement $paymentId récupérés');
      return response;
    } catch (error) {
      print('❌ ERREUR getPaymentDetails: $error');
      throw Exception('Erreur lors de la récupération des détails: $error');
    }
  }

  /// Met à jour le statut d'un paiement
  Future<void> updatePaymentStatus(
    String paymentId,
    String newStatus, {
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      String supabaseStatus = _getSupabaseStatus(newStatus);
      String? supabasePaymentMethod;

      if (paymentMethod != null) {
        supabasePaymentMethod = _getSupabasePaymentMethod(paymentMethod);
      }

      Map<String, dynamic> updates = {'statut': supabaseStatus};

      // Si le paiement est marqué comme payé, mettre la date
      if (newStatus == 'paid') {
        updates['date_paiement'] =
            DateTime.now().toIso8601String().split('T')[0];
        if (supabasePaymentMethod != null) {
          updates['mode_paiement'] = supabasePaymentMethod;
        }
      } else if (newStatus == 'pending' || newStatus == 'overdue') {
        // Retirer la date de paiement pour les statuts non payés
        updates['date_paiement'] = null;
      }

      if (notes != null) {
        updates['notes'] = notes;
      }

      await _supabase.from('paiements').update(updates).eq('id', paymentId);

      print('✅ Statut du paiement $paymentId mis à jour vers $supabaseStatus');
    } catch (error) {
      print('❌ ERREUR updatePaymentStatus: $error');
      throw Exception('Erreur lors de la mise à jour du statut: $error');
    }
  }

  /// Crée un nouveau paiement
  Future<Map<String, dynamic>> createPayment(
    Map<String, dynamic> paymentData,
  ) async {
    try {
      final response = await _supabase
          .from('paiements')
          .insert({
            'bail_id': paymentData['leaseId'],
            'montant': paymentData['amount'],
            'date_echeance': paymentData['dueDate'],
            'mois_concerne': paymentData['monthConcerned'],
            'statut': _getSupabaseStatus(
              paymentData['status'] ?? 'pending',
            ),
            'mode_paiement': _getSupabasePaymentMethod(
              paymentData['paymentMethod'],
            ),
            'notes': paymentData['notes'],
          })
          .select()
          .single();

      print('✅ Nouveau paiement créé: ${response['id']}');
      return response;
    } catch (error) {
      print('❌ ERREUR createPayment: $error');
      throw Exception('Erreur lors de la création du paiement: $error');
    }
  }

  /// Marque un paiement comme payé
  Future<void> markPaymentAsPaid(String paymentId) async {
    try {
      final response = await _supabase
          .from('paiements')
          .update({
            'statut': 'Payé',
            'date_paiement': DateTime.now().toIso8601String(),
          })
          .eq('id', paymentId)
          .select();

      if (response.isEmpty) {
        throw Exception('Paiement non trouvé');
      }

      print('✅ Paiement marqué comme payé: $paymentId');
    } catch (e) {
      print('❌ Erreur marquer paiement payé: $e');
      throw Exception('Impossible de marquer le paiement comme payé: $e');
    }
  }

  /// Détermine l'urgence du paiement
  String _determineUrgency(
    String? statut,
    String? dateEcheance,
    String? datePaiement,
  ) {
    // Handle null values with safe defaults
    final safeStatut = statut ?? '';
    final safeDateEcheance = dateEcheance ?? '';

    if (safeStatut == 'En retard') return 'high';

    if (datePaiement != null && datePaiement.isNotEmpty)
      return 'low'; // Déjà payé

    if (safeDateEcheance.isEmpty) return 'low'; // Can't determine without date

    try {
      DateTime dueDate = DateTime.parse(safeDateEcheance);
      DateTime now = DateTime.now();
      int daysUntilDue = dueDate.difference(now).inDays;

      if (daysUntilDue < 0) return 'high'; // En retard
      if (daysUntilDue <= 3) return 'medium'; // Dans 3 jours

      return 'low';
    } catch (e) {
      print(
        '❌ Error parsing date in _determineUrgency: $safeDateEcheance - $e',
      );
      return 'low'; // Safe fallback
    }
  }

  /// Convertit le statut Supabase en code
  String _getStatusCode(String? supabaseStatus) {
    final safeStatus = supabaseStatus ?? '';
    switch (safeStatus) {
      case 'Payé':
        return 'paid';
      case 'En attente':
        return 'pending';
      case 'En retard':
        return 'overdue';
      default:
        return 'pending';
    }
  }

  /// Convertit le code de statut en statut Supabase
  String _getSupabaseStatus(String? statusCode) {
    final safeStatusCode = statusCode ?? '';
    switch (safeStatusCode) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return 'En attente';
    }
  }

  /// Convertit le mode de paiement Supabase en code
  String? _getPaymentMethodCode(String? supabaseMethod) {
    if (supabaseMethod == null || supabaseMethod.isEmpty) return null;

    switch (supabaseMethod) {
      case 'Espèces':
        return 'cash';
      case 'Virement':
        return 'transfer';
      case 'Mobile Money':
        return 'mobile_money';
      case 'Chèque':
        return 'check';
      default:
        return 'cash';
    }
  }

  /// Convertit le code de mode de paiement en mode Supabase
  String _getSupabasePaymentMethod(String? methodCode) {
    if (methodCode == null || methodCode.isEmpty) return 'Espèces';

    switch (methodCode) {
      case 'cash':
        return 'Espèces';
      case 'transfer':
        return 'Virement';
      case 'mobile_money':
        return 'Mobile Money';
      case 'check':
        return 'Chèque';
      default:
        return 'Espèces';
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
