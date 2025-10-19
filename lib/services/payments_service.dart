import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PaymentsService {
  static final PaymentsService _instance = PaymentsService._internal();
  factory PaymentsService() => _instance;
  PaymentsService._internal();

  final _supabase = Supabase.instance.client;

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
        baux!inner(
          numero_contrat,
          commercants!inner(nom),
          locaux!inner(numero)
        )
      ''').order('date_echeance', ascending: false);

      List<Map<String, dynamic>> payments = [];
      final dateFormat = DateFormat('dd/MM/yyyy');

      for (var paiement in response) {
        // Calculer les jours de retard si applicable
        int? daysOverdue;
        if (paiement['statut'] == 'En retard') {
          final echeance = DateTime.parse(paiement['date_echeance']);
          final maintenant = DateTime.now();
          daysOverdue = maintenant.difference(echeance).inDays;
        }

        payments.add({
          'id': paiement['id'],
          'merchantName': paiement['baux']['commercants']['nom'],
          'propertyNumber': paiement['baux']['locaux']['numero'],
          'amount':
              '${NumberFormat('#,###', 'fr_FR').format(paiement['montant'])} FCFA',
          'dueDate':
              dateFormat.format(DateTime.parse(paiement['date_echeance'])),
          'status': _convertStatusToUI(paiement['statut']),
          'description': 'Loyer mensuel ${paiement['mois_concerne']}',
          if (paiement['date_paiement'] != null)
            'paidDate':
                dateFormat.format(DateTime.parse(paiement['date_paiement'])),
          if (daysOverdue != null) 'daysOverdue': daysOverdue,
          'rawMontant': paiement['montant'],
          'rawStatus': paiement['statut'],
          'contractNumber': paiement['baux']['numero_contrat'],
          'paymentMethod': paiement['mode_paiement'],
          'notes': paiement['notes'],
        });
      }

      print('✅ Récupération de ${payments.length} paiements depuis Supabase');
      return payments;
    } catch (error) {
      print('❌ ERREUR getAllPayments: $error');
      throw Exception('Erreur lors de la récupération des paiements: $error');
    }
  }

  /// Récupère les paiements par statut
  Future<List<Map<String, dynamic>>> getPaymentsByStatus(String status) async {
    try {
      final allPayments = await getAllPayments();
      if (status == 'all') return allPayments;

      return allPayments
          .where((payment) => payment['status'] == status)
          .toList();
    } catch (error) {
      print('❌ ERREUR getPaymentsByStatus: $error');
      throw Exception('Erreur lors du filtrage par statut: $error');
    }
  }

  /// Enregistre un paiement
  Future<void> recordPayment(String paymentId) async {
    try {
      await _supabase.from('paiements').update({
        'statut': 'Payé',
        'date_paiement': DateTime.now().toIso8601String().split('T')[0],
      }).eq('id', paymentId);

      print('✅ Paiement $paymentId enregistré');
    } catch (error) {
      print('❌ ERREUR recordPayment: $error');
      throw Exception('Erreur lors de l\'enregistrement du paiement: $error');
    }
  }

  /// Crée un nouveau paiement
  Future<Map<String, dynamic>> createPayment(
      Map<String, dynamic> paymentData) async {
    try {
      final response = await _supabase
          .from('paiements')
          .insert({
            'bail_id': paymentData['bailId'],
            'montant': paymentData['montant'],
            'date_echeance': paymentData['dateEcheance'],
            'mois_concerne': paymentData['moisConcerne'],
            'statut': paymentData['statut'] ?? 'En attente',
            'mode_paiement': paymentData['modePaiement'],
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

  /// Récupère les métriques des paiements
  Future<Map<String, dynamic>> getPaymentMetrics() async {
    try {
      final allPayments = await getAllPayments();

      final paidPayments =
          allPayments.where((p) => p['status'] == 'paid').toList();
      final pendingPayments =
          allPayments.where((p) => p['status'] == 'pending').toList();
      final overduePayments =
          allPayments.where((p) => p['status'] == 'overdue').toList();

      double totalCollected = 0;
      double totalPending = 0;
      double totalOverdue = 0;

      for (var payment in paidPayments) {
        totalCollected += payment['rawMontant'] ?? 0;
      }
      for (var payment in pendingPayments) {
        totalPending += payment['rawMontant'] ?? 0;
      }
      for (var payment in overduePayments) {
        totalOverdue += payment['rawMontant'] ?? 0;
      }

      return {
        'totalCollected': totalCollected,
        'totalPending': totalPending,
        'totalOverdue': totalOverdue,
        'paidCount': paidPayments.length,
        'pendingCount': pendingPayments.length,
        'overdueCount': overduePayments.length,
      };
    } catch (error) {
      print('❌ ERREUR getPaymentMetrics: $error');
      throw Exception('Erreur lors du calcul des métriques: $error');
    }
  }

  /// Convertit le statut Supabase vers l'UI
  String _convertStatusToUI(String supabaseStatus) {
    switch (supabaseStatus) {
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

  /// Convertit le statut UI vers Supabase
  String _convertStatusToSupabase(String uiStatus) {
    switch (uiStatus) {
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
}
