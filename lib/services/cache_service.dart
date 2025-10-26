import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
    print('✅ Cache local initialisé avec SharedPreferences');
  }

  // ═══════════════════════════════════════════════════════
  // COMMERCANTS
  // ═══════════════════════════════════════════════════════

  Future<void> cacheCommercants(List<dynamic> data) async {
    if (!_isInitialized || _prefs == null) return;

    final jsonString = jsonEncode(data);
    await _prefs!.setString('commercants', jsonString);
    await _setLastSync('commercants');
    print('💾 ${data.length} commerçants mis en cache');
  }

  List<dynamic> getCommercants() {
    if (!_isInitialized || _prefs == null) return [];

    final jsonString = _prefs!.getString('commercants');
    if (jsonString == null) return [];

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Erreur décodage cache commercants: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════
  // LOCAUX
  // ═══════════════════════════════════════════════════════

  Future<void> cacheLocaux(List<dynamic> data) async {
    if (!_isInitialized || _prefs == null) return;

    final jsonString = jsonEncode(data);
    await _prefs!.setString('locaux', jsonString);
    await _setLastSync('locaux');
    print('💾 ${data.length} locaux mis en cache');
  }

  List<dynamic> getLocaux() {
    if (!_isInitialized || _prefs == null) return [];

    final jsonString = _prefs!.getString('locaux');
    if (jsonString == null) return [];

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Erreur décodage cache locaux: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════
  // BAUX
  // ═══════════════════════════════════════════════════════

  Future<void> cacheBaux(List<dynamic> data) async {
    if (!_isInitialized || _prefs == null) return;

    final jsonString = jsonEncode(data);
    await _prefs!.setString('baux', jsonString);
    await _setLastSync('baux');
    print('💾 ${data.length} baux mis en cache');
  }

  List<dynamic> getBaux() {
    if (!_isInitialized || _prefs == null) return [];

    final jsonString = _prefs!.getString('baux');
    if (jsonString == null) return [];

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Erreur décodage cache baux: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════
  // PAIEMENTS
  // ═══════════════════════════════════════════════════════

  Future<void> cachePaiements(List<dynamic> data) async {
    if (!_isInitialized || _prefs == null) return;

    final jsonString = jsonEncode(data);
    await _prefs!.setString('paiements', jsonString);
    await _setLastSync('paiements');
    print('💾 ${data.length} paiements mis en cache');
  }

  List<dynamic> getPaiements() {
    if (!_isInitialized || _prefs == null) return [];

    final jsonString = _prefs!.getString('paiements');
    if (jsonString == null) return [];

    try {
      return jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      print('❌ Erreur décodage cache paiements: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════
  // METADATA
  // ═══════════════════════════════════════════════════════

  Future<void> _setLastSync(String entity) async {
    if (!_isInitialized || _prefs == null) return;
    await _prefs!
        .setString('last_sync_$entity', DateTime.now().toIso8601String());
  }

  String? getLastSync(String entity) {
    if (!_isInitialized || _prefs == null) return null;
    return _prefs!.getString('last_sync_$entity');
  }

  Future<void> clearAllCache() async {
    if (!_isInitialized || _prefs == null) return;

    final keys = ['commercants', 'locaux', 'baux', 'paiements'];
    for (final key in keys) {
      await _prefs!.remove(key);
      await _prefs!.remove('last_sync_$key');
    }
    print('🗑️ Cache vidé');
  }

  // Vérifier si cache est vide
  bool isCacheEmpty() {
    if (!_isInitialized || _prefs == null) return true;

    return !_prefs!.containsKey('commercants') &&
        !_prefs!.containsKey('locaux') &&
        !_prefs!.containsKey('baux') &&
        !_prefs!.containsKey('paiements');
  }
}
