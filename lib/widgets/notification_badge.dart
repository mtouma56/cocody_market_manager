import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationBadge extends StatefulWidget {
  @override
  _NotificationBadgeState createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    await _notifService.rafraichirCompteurs();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final total = _notifService.totalNotifications;

    return IconButton(
      icon: Stack(
        children: [
          Icon(Icons.notifications_outlined),
          if (total > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Text(
                  total > 99 ? '99+' : '$total',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () {
        _showNotificationsPanel(context);
      },
    );
  }

  void _showNotificationsPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => NotificationsPanel(),
    );
  }
}

class NotificationsPanel extends StatelessWidget {
  final _notifService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final retards = _notifService.paiementsEnRetard;
    final baux = _notifService.bauxExpirantBientot;

    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (retards > 0)
            _buildNotificationCard(
              context,
              icon: Icons.warning,
              color: Colors.red,
              title: 'Paiements en retard',
              subtitle:
                  '$retards paiement${retards > 1 ? 's' : ''} nécessite${retards > 1 ? 'nt' : ''} votre attention',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/overdue-payments-screen');
              },
            ),
          if (retards > 0 && baux > 0) SizedBox(height: 12),
          if (baux > 0)
            _buildNotificationCard(
              context,
              icon: Icons.event_note,
              color: Colors.orange,
              title: 'Baux expirant bientôt',
              subtitle:
                  '$baux bail${baux > 1 ? 'aux' : ''} expire${baux > 1 ? 'nt' : ''} dans les 30 jours',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/expiring-leases-screen');
              },
            ),
          if (retards == 0 && baux == 0)
            Center(
              child: Column(
                children: [
                  SizedBox(height: 20),
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green.shade300,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucune alerte',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tout est à jour !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(51),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
