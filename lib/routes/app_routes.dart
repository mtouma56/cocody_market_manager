import 'package:flutter/material.dart';
import '../presentation/dashboard_screen/dashboard_screen.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/properties_management_screen/properties_management_screen.dart';
import '../presentation/merchants_management_screen/merchants_management_screen.dart';
import '../presentation/merchant_details_screen/merchant_details_screen.dart';
import '../presentation/property_details_screen/property_details_screen.dart';
import '../presentation/lease_management_screen/lease_management_screen.dart';
import '../presentation/add_lease_form_screen/add_lease_form_screen.dart';
import '../presentation/payments_management_screen/payments_management_screen.dart';
import '../presentation/add_payment_form_screen/add_payment_form_screen.dart';
import '../presentation/payment_service_integration_screen/payment_service_integration_screen.dart';
import '../presentation/settings_screen/settings_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String dashboardScreen = '/dashboard-screen';
  static const String propertiesManagementScreen =
      '/properties-management-screen';
  static const String merchantsManagementScreen =
      '/merchants-management-screen';
  static const String merchantDetailsScreen = '/merchant-details-screen';
  static const String propertyDetailsScreen = '/property-details-screen';
  static const String leaseManagementScreen = '/lease-management-screen';
  static const String addLeaseFormScreen = '/add-lease-form-screen';
  static const String paymentsManagementScreen = '/payments-management-screen';
  static const String addPaymentFormScreen = '/add-payment-form-screen';
  static const String paymentServiceIntegrationScreen =
      '/payment-service-integration-screen';
  static const String settingsScreen = '/settings-screen';

  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    dashboardScreen: (context) => const DashboardScreen(),
    propertiesManagementScreen: (context) => const PropertiesManagementScreen(),
    merchantsManagementScreen: (context) => const MerchantsManagementScreen(),
    merchantDetailsScreen: (context) {
      final merchantId =
          ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return MerchantDetailsScreen(merchantId: merchantId);
    },
    propertyDetailsScreen: (context) {
      final propertyId =
          ModalRoute.of(context)!.settings.arguments as String? ?? '';
      return PropertyDetailsScreen(propertyId: propertyId);
    },
    leaseManagementScreen: (context) => const LeaseManagementScreen(),
    addLeaseFormScreen: (context) => const AddLeaseFormScreen(),
    paymentsManagementScreen: (context) => const PaymentsManagementScreen(),
    addPaymentFormScreen: (context) => const AddPaymentFormScreen(),
    paymentServiceIntegrationScreen: (context) =>
        const PaymentServiceIntegrationScreen(),
    settingsScreen: (context) => const SettingsScreen(),
  };
}
