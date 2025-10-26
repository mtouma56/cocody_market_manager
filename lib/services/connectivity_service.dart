import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  StreamSubscription? _subscription;

  Future<void> initialize() async {
    // Vérifier statut initial
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);

    // Écouter les changements
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      _updateStatus(result);
    });

    print(
        '✅ Connectivité initialisée : ${_isOnline ? "EN LIGNE" : "HORS LIGNE"}');
  }

  void _updateStatus(List<ConnectivityResult> results) {
    // Considérer en ligne si au moins une connexion active
    final wasOnline = _isOnline;
    _isOnline = results.any((result) => result != ConnectivityResult.none);

    if (wasOnline != _isOnline) {
      print(
          '🔄 Connectivité changée : ${_isOnline ? "EN LIGNE" : "HORS LIGNE"}');
      _statusController.add(_isOnline);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
