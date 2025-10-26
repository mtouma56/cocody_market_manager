import 'package:supabase_flutter/supabase_flutter.dart';

class BailValidationService {
  final supabase = Supabase.instance.client;

  /// Vérifie qu'un local n'a pas déjà un bail actif
  Future<ValidationResult> verifierLocalDisponible(String localId) async {
    try {
      final bailsActifs = await supabase.from('baux').select('''
          id,
          numero_contrat,
          date_debut,
          date_fin,
          montant_loyer,
          commercants(nom, contact)
        ''').eq('local_id', localId).eq('statut', 'Actif');

      if (bailsActifs.isNotEmpty) {
        final bail = bailsActifs.first;
        return ValidationResult(
          isValid: false,
          message: 'Ce local a déjà un bail actif',
          bailExistant: bail,
        );
      }

      return ValidationResult(isValid: true, message: 'Local disponible');
    } catch (e) {
      return ValidationResult(
        isValid: false,
        message: 'Erreur de vérification: $e',
      );
    }
  }

  /// Récupère tous les conflits (pour debug/admin)
  Future<List<Map<String, dynamic>>> getConflits() async {
    try {
      final conflits = await supabase.rpc('get_locaux_conflits');
      return List<Map<String, dynamic>>.from(conflits);
    } catch (e) {
      print('❌ Erreur récupération conflits: $e');
      return [];
    }
  }

  /// Résout automatiquement tous les conflits détectés
  Future<List<Map<String, dynamic>>> resoudreConflits() async {
    try {
      final resolutions = await supabase.rpc('resoudre_conflits_baux');
      return List<Map<String, dynamic>>.from(resolutions);
    } catch (e) {
      print('❌ Erreur résolution conflits: $e');
      rethrow;
    }
  }

  /// Vérifie la disponibilité d'un local avant création de bail
  Future<LocalAvailabilityResult> checkLocalAvailability(String localId) async {
    try {
      // Récupérer les informations du local
      final local = await supabase.from('locaux').select('''
          id,
          numero,
          statut,
          types_locaux(nom),
          etages(nom)
        ''').eq('id', localId).single();

      // Vérifier s'il y a un bail actif
      final validationResult = await verifierLocalDisponible(localId);

      return LocalAvailabilityResult(
        local: local,
        isAvailable: validationResult.isValid,
        message: validationResult.message,
        existingLease: validationResult.bailExistant,
      );
    } catch (e) {
      return LocalAvailabilityResult(
        local: null,
        isAvailable: false,
        message: 'Erreur lors de la vérification: $e',
        existingLease: null,
      );
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String message;
  final Map<String, dynamic>? bailExistant;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.bailExistant,
  });
}

class LocalAvailabilityResult {
  final Map<String, dynamic>? local;
  final bool isAvailable;
  final String message;
  final Map<String, dynamic>? existingLease;

  LocalAvailabilityResult({
    required this.local,
    required this.isAvailable,
    required this.message,
    this.existingLease,
  });
}
