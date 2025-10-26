import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  final supabase = Supabase.instance.client;

  bool _isInitialized = false;

  // Compteurs pour badges
  int _paiementsEnRetard = 0;
  int _bauxExpirantBientot = 0;

  int get paiementsEnRetard => _paiementsEnRetard;
  int get bauxExpirantBientot => _bauxExpirantBientot;
  int get totalNotifications => _paiementsEnRetard + _bauxExpirantBientot;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Configuration Android
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuration iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialiser
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander permissions iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _isInitialized = true;
    print('✅ Notifications initialisées (Android + iOS)');

    // Charger compteurs au démarrage
    await rafraichirCompteurs();
  }

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // TODO: Navigation selon payload
  }

  /// Rafraîchir les compteurs
  Future<void> rafraichirCompteurs() async {
    try {
      final now = DateTime.now();

      // Compter paiements en retard
      final paiementsRetard = await supabase
          .from('paiements')
          .select('id')
          .eq('statut', 'En retard')
          .count();

      _paiementsEnRetard = paiementsRetard.count;

      // Compter baux expirant dans 30 jours
      final dateLimit = now.add(Duration(days: 30));
      final bauxExpirant = await supabase
          .from('baux')
          .select('id')
          .eq('statut', 'Actif')
          .lte('date_fin', dateLimit.toIso8601String())
          .count();

      _bauxExpirantBientot = bauxExpirant.count;

      print(
          '📊 Notifications : $_paiementsEnRetard retards, $_bauxExpirantBientot baux');

      // Sauvegarder pour persistance
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('notif_retards', _paiementsEnRetard);
      await prefs.setInt('notif_baux', _bauxExpirantBientot);
    } catch (e) {
      print('❌ Erreur compteurs: $e');
    }
  }

  /// Afficher notification paiements en retard
  Future<void> notifierPaiementsEnRetard(int nombre) async {
    if (nombre == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'paiements_retard',
      'Paiements en retard',
      channelDescription: 'Alertes pour paiements en retard',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFF5252),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: null,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      '⚠️ Paiements en retard',
      '$nombre paiement${nombre > 1 ? 's' : ''} en retard nécessite${nombre > 1 ? 'nt' : ''} votre attention',
      details,
      payload: 'paiements_retard',
    );
  }

  /// Afficher notification baux expirant
  Future<void> notifierBauxExpirant(int nombre) async {
    if (nombre == 0) return;

    const androidDetails = AndroidNotificationDetails(
      'baux_expiration',
      'Baux expirant bientôt',
      channelDescription: 'Alertes pour baux arrivant à expiration',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFA726),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: null,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      '📋 Baux expirant bientôt',
      '$nombre bail${nombre > 1 ? 'aux' : ''} expire${nombre > 1 ? 'nt' : ''} dans les 30 prochains jours',
      details,
      payload: 'baux_expiration',
    );
  }

  /// Planifier vérification quotidienne (9h du matin)
  Future<void> planifierVerificationQuotidienne() async {
    await _notifications.cancelAll();

    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(Duration(days: 1));
    }

    await _notifications.show(
      0,
      'Vérification quotidienne',
      'Vérification des paiements et baux...',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'verification_quotidienne',
          'Vérification quotidienne',
          channelDescription: 'Vérification automatique des alertes',
          importance: Importance.low,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
    );

    print('✅ Vérification quotidienne planifiée pour 9h');
  }

  /// Vérifier et notifier si nécessaire
  Future<void> verifierEtNotifier() async {
    await rafraichirCompteurs();

    if (_paiementsEnRetard > 0) {
      await notifierPaiementsEnRetard(_paiementsEnRetard);
    }

    if (_bauxExpirantBientot > 0) {
      await notifierBauxExpirant(_bauxExpirantBientot);
    }
  }

  /// Annuler toutes les notifications
  Future<void> annulerToutes() async {
    await _notifications.cancelAll();
  }
}