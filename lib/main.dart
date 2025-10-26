import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './services/cache_service.dart';
import './services/connectivity_service.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './services/sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Active les logs Supabase
  try {
    await SupabaseService.initialize();
    debugPrint('✅ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
  }

  // Initialiser cache local
  try {
    await CacheService().initialize();
    debugPrint('✅ Cache local initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize cache: $e');
  }

  // Initialiser connectivité
  try {
    await ConnectivityService().initialize();
    debugPrint('✅ Connectivity service initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize connectivity: $e');
  }

  // Initialiser synchronisation
  try {
    SyncService().initialize();
    debugPrint('✅ Sync service initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize sync service: $e');
  }

  // Sync initiale si en ligne
  try {
    if (ConnectivityService().isOnline) {
      SyncService().syncAll();
      debugPrint('✅ Initial sync started');
    } else {
      debugPrint('📡 Starting in offline mode');
    }
  } catch (e) {
    debugPrint('❌ Failed initial sync: $e');
  }

  // Initialiser notifications (Android + iOS)
  try {
    await NotificationService().initialize();
    debugPrint('✅ Notifications initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize notifications: $e');
  }

  bool _hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!_hasShownError) {
      _hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        _hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp(
          title: 'cocody_market_manager',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.splashScreen,
        );
      },
    );
  }
}
