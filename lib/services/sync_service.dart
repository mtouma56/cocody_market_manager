import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import './cache_service.dart';
import './connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _supabase = Supabase.instance.client;
  final _connectivity = ConnectivityService();
  final _cache = CacheService();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  final _syncController = StreamController<String>.broadcast();
  Stream<String> get syncStream => _syncController.stream;

  StreamSubscription? _connectivitySubscription;

  void initialize() {
    // Écouter les changements de connectivité
    _connectivitySubscription = _connectivity.statusStream.listen((isOnline) {
      if (isOnline) {
        print('🔄 Connexion rétablie, synchronisation...');
        syncAll();
      }
    });

    print('✅ Sync service initialisé');
  }

  /// Synchroniser toutes les données
  Future<void> syncAll() async {
    if (_isSyncing) {
      print('⏳ Sync déjà en cours, skip');
      return;
    }

    if (!_connectivity.isOnline) {
      print('📡 Hors ligne, utilisation du cache');
      return;
    }

    _isSyncing = true;
    _syncController.add('Synchronisation...');

    try {
      // Sync dans l'ordre des dépendances
      await _syncCommercants();
      await _syncLocaux();
      await _syncBaux();
      await _syncPaiements();

      _syncController.add('Synchronisation terminée');
      print('✅ Synchronisation complète terminée');
    } catch (e) {
      print('❌ Erreur sync: $e');
      _syncController.add('Erreur synchronisation');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncCommercants() async {
    try {
      final data = await _supabase.from('commercants').select('*').order('nom');

      await _cache.cacheCommercants(data);
      _syncController.add('Commerçants synchronisés');
    } catch (e) {
      print('❌ Erreur sync commerçants: $e');
      rethrow;
    }
  }

  Future<void> _syncLocaux() async {
    try {
      final data = await _supabase.from('locaux').select('*').order('numero');

      await _cache.cacheLocaux(data);
      _syncController.add('Locaux synchronisés');
    } catch (e) {
      print('❌ Erreur sync locaux: $e');
      rethrow;
    }
  }

  Future<void> _syncBaux() async {
    try {
      final data = await _supabase.from('baux').select('''
          *,
          commercants(id, nom, contact, email),
          locaux(id, numero, statut)
        ''').order('created_at', ascending: false);

      await _cache.cacheBaux(data);
      _syncController.add('Baux synchronisés');
    } catch (e) {
      print('❌ Erreur sync baux: $e');
      rethrow;
    }
  }

  Future<void> _syncPaiements() async {
    try {
      final data = await _supabase.from('paiements').select('''
          *,
          baux!inner(
            numero_contrat,
            commercants(id, nom),
            locaux(numero)
          )
        ''').order('date_echeance', ascending: false);

      await _cache.cachePaiements(data);
      _syncController.add('Paiements synchronisés');
    } catch (e) {
      print('❌ Erreur sync paiements: $e');
      rethrow;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncController.close();
  }
}
