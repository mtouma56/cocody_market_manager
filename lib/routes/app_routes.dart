import 'package:flutter/material.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/properties_management_screen/properties_management_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/lease_management_screen/lease_management_screen.dart';
import '../presentation/payments_management_screen/payments_management_screen.dart';
import '../presentation/merchants_management_screen/merchants_management_screen.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String dashboard = '/dashboard-screen';
  static const String splash = '/splash-screen';
  static const String propertiesManagement = '/properties-management-screen';
  static const String settings = '/settings-screen';
  static const String login = '/login-screen';
  static const String leaseManagement = '/lease-management-screen';
  static const String paymentsManagement = '/payments-management-screen';
  static const String merchantsManagement = '/merchants-management-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    dashboard: (context) => const DashboardScreen(),
    splash: (context) => const SplashScreen(),
    propertiesManagement: (context) => const PropertiesManagementScreen(),
    settings: (context) => const SettingsScreen(),
    login: (context) => const LoginScreen(),
    leaseManagement: (context) => const LeaseManagementScreen(),
    paymentsManagement: (context) => const PaymentsManagementScreen(),
    merchantsManagement: (context) => const MerchantsManagementScreen(),
    // TODO: Add your other routes here
  };
}
