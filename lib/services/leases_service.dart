import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class LeasesService {
  static final LeasesService _instance = LeasesService._internal();
  factory LeasesService() => _instance;
  LeasesService._internal();

  final _supabase = Supabase.instance.client;

  /// Récupère tous les baux avec leurs informations complètes
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
        commercants!inner(nom, activite, contact, email),
        locaux!inner(
          numero,
          etages!inner(nom, ordre),
          types_locaux!inner(nom, surface_m2)
        )
      ''').eq('actif', true).order('created_at', ascending: false);

      List<Map<String, dynamic>> leases = [];

      for (var bail in response) {
        final dateFormat = DateFormat('dd/MM/yyyy');

        leases.add({
          'id': bail['id'],
          'contractNumber': bail['numero_contrat'],
          'merchantName': bail['commercants']['nom'],
          'propertyType': bail['locaux']['types_locaux']['nom'],
          'propertyLocation':
              '${bail['locaux']['etages']['nom']} - Local ${bail['locaux']['numero']}',
          'startDate': dateFormat.format(DateTime.parse(bail['date_debut'])),
          'endDate': dateFormat.format(DateTime.parse(bail['date_fin'])),
          'startDateRaw': bail['date_debut'],
          'endDateRaw': bail['date_fin'],
          'monthlyRent':
              NumberFormat('#,###', 'fr_FR').format(bail['montant_loyer']),
          'status': bail['statut'],
          'merchantPhone': bail['commercants']['contact'] ?? '',
          'merchantEmail': bail['commercants']['email'] ?? '',
          'businessType': bail['commercants']['activite'],
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
      final allLeases = await getAllLeases();
      if (status == 'Tous') return allLeases;

      return allLeases.where((lease) => lease['status'] == status).toList();
    } catch (error) {
      print('❌ ERREUR getLeasesByStatus: $error');
      throw Exception('Erreur lors du filtrage par statut: $error');
    }
  }

  /// Met à jour le statut d'un bail
  Future<void> updateLeaseStatus(String leaseId, String newStatus) async {
    try {
      await _supabase
          .from('baux')
          .update({'statut': newStatus}).eq('id', leaseId);

      print('✅ Statut du bail $leaseId mis à jour vers $newStatus');
    } catch (error) {
      print('❌ ERREUR updateLeaseStatus: $error');
      throw Exception('Erreur lors de la mise à jour du statut: $error');
    }
  }

  /// Crée un nouveau bail
  Future<Map<String, dynamic>> createLease(
      Map<String, dynamic> leaseData) async {
    try {
      final response = await _supabase
          .from('baux')
          .insert({
            'numero_contrat': leaseData['contractNumber'],
            'commercant_id': leaseData['merchantId'],
            'local_id': leaseData['propertyId'],
            'date_debut': leaseData['startDate'],
            'date_fin': leaseData['endDate'],
            'montant_loyer': leaseData['monthlyRent'],
            'statut': leaseData['status'] ?? 'Actif',
          })
          .select()
          .single();

      print('✅ Nouveau bail créé: ${response['numero_contrat']}');
      return response;
    } catch (error) {
      print('❌ ERREUR createLease: $error');
      throw Exception('Erreur lors de la création du bail: $error');
    }
  }

  /// Termine/résilie un bail
  Future<void> terminateLease(String leaseId) async {
    try {
      await _supabase.from('baux').update({
        'statut': 'Expiré',
        'actif': false,
      }).eq('id', leaseId);

      print('✅ Bail $leaseId résilié');
    } catch (error) {
      print('❌ ERREUR terminateLease: $error');
      throw Exception('Erreur lors de la résiliation: $error');
    }
  }

  /// Récupère les statistiques des baux
  Future<Map<String, int>> getLeasesStats() async {
    try {
      final allLeases = await getAllLeases();

      return {
        'total': allLeases.length,
        'actif': allLeases.where((l) => l['status'] == 'Actif').length,
        'expire_bientot':
            allLeases.where((l) => l['status'] == 'Expire bientôt').length,
        'expire': allLeases.where((l) => l['status'] == 'Expiré').length,
        'brouillon': allLeases.where((l) => l['status'] == 'Brouillon').length,
      };
    } catch (error) {
      print('❌ ERREUR getLeasesStats: $error');
      throw Exception('Erreur lors du calcul des statistiques: $error');
    }
  }
}
