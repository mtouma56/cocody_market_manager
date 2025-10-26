import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class ConnectivityIndicator extends StatefulWidget {
  @override
  _ConnectivityIndicatorState createState() => _ConnectivityIndicatorState();
}

class _ConnectivityIndicatorState extends State<ConnectivityIndicator> {
  final _connectivity = ConnectivityService();
  final _sync = SyncService();

  bool _isOnline = true;
  String _syncMessage = '';

  @override
  void initState() {
    super.initState();
    _isOnline = _connectivity.isOnline;

    // Écouter les changements de statut
    _connectivity.statusStream.listen((isOnline) {
      if (mounted) {
        setState(() => _isOnline = isOnline);
      }
    });

    // Écouter les messages de sync
    _sync.syncStream.listen((message) {
      if (mounted) {
        setState(() => _syncMessage = message);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ne rien afficher si en ligne et pas de sync
    if (_isOnline && !_sync.isSyncing) {
      return SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _isOnline ? Colors.blue.shade50 : Colors.orange.shade50,
        border: Border(
          bottom: BorderSide(
            color: _isOnline ? Colors.blue.shade200 : Colors.orange.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sync.isSyncing)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.blue),
              ),
            )
          else
            Icon(
              _isOnline ? Icons.cloud_done : Icons.cloud_off,
              size: 16,
              color: _isOnline ? Colors.blue : Colors.orange,
            ),
          SizedBox(width: 8),
          Text(
            _sync.isSyncing
                ? _syncMessage
                : (_isOnline ? 'En ligne' : 'Mode hors ligne'),
            style: TextStyle(
              fontSize: 12,
              color: _isOnline ? Colors.blue.shade900 : Colors.orange.shade900,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
