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

  StreamSubscription<ConnectivityResult>? _subscription;

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

  void _updateStatus(ConnectivityResult result) {
    // Considérer en ligne si la connexion est active
    final wasOnline = _isOnline;
    _isOnline = result != ConnectivityResult.none;

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
