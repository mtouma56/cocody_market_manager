import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import './widgets/app_logo_widget.dart';
import './widgets/biometric_auth_widget.dart';
import './widgets/login_form_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  String? _errorMessage;

  // Mock credentials for testing
  final Map<String, String> _mockCredentials = {
    'admin@cocodymarket.com': 'admin123',
    'manager@cocodymarket.com': 'manager123',
    'supervisor@cocodymarket.com': 'super123',
  };

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadSavedEmail();
  }

  Future<void> _checkBiometricAvailability() async {
    // Simulate biometric availability check
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isBiometricAvailable = true;
      });
    }
  }

  Future<void> _loadSavedEmail() async {
    // Simulate loading saved email from secure storage
    await Future.delayed(const Duration(milliseconds: 300));
    // Implementation would use shared_preferences or secure storage
  }

  Future<void> _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 2));

      // Check mock credentials
      if (_mockCredentials.containsKey(email) &&
          _mockCredentials[email] == password) {
        // Success - trigger haptic feedback
        HapticFeedback.mediumImpact();

        // 🔧 FIX: Verify Supabase initialization for mock login
        // The RLS policies allow public SELECT access, so no auth is needed for reading
        // But we need to ensure Supabase is properly initialized
        try {
          final supabase = Supabase.instance.client;

          // Test if Supabase is accessible by making a simple query
          debugPrint('🔍 Testing Supabase connection...');
          final testQuery = await supabase.from('etages').select('id').limit(1);
          debugPrint('✅ Supabase is accessible - found ${testQuery.length} etage(s)');
          debugPrint('📝 Mock login successful - RLS public policies allow data access');
        } catch (supabaseError) {
          // This is the likely cause of "Something went wrong"
          debugPrint('❌ CRITICAL: Supabase connection failed: $supabaseError');
          debugPrint('💡 Make sure to run: flutter run --dart-define-from-file=env.json');

          // Show error to user
          if (mounted) {
            setState(() {
              _errorMessage =
                'Erreur de configuration Supabase.\n'
                'Assurez-vous que l\'app est lancée avec:\n'
                'flutter run --dart-define-from-file=env.json';
              _isLoading = false;
            });
            return;
          }
        }

        // Save email for next login
        await _saveEmail(email);

        // Navigate to dashboard
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/dashboard-screen',
            (route) => false,
          );
        }
      } else {
        // Invalid credentials
        setState(() {
          _errorMessage =
              'Adresse e-mail ou mot de passe incorrect. Veuillez réessayer.';
        });
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      // Network or other error
      setState(() {
        _errorMessage =
            'Erreur de connexion. Vérifiez votre connexion internet et réessayez.';
      });
      HapticFeedback.heavyImpact();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricAuth() async {
    try {
      HapticFeedback.lightImpact();

      // Simulate biometric authentication
      await Future.delayed(const Duration(seconds: 1));

      // Success - navigate to dashboard
      HapticFeedback.mediumImpact();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/dashboard-screen',
          (route) => false,
        );
      }
    } catch (e) {
      // Biometric authentication failed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Authentification biométrique échouée. Utilisez votre mot de passe.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveEmail(String email) async {
    // Implementation would use shared_preferences
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.setString('saved_email', email);
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: _dismissKeyboard,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 8.h),

                    // App Logo
                    const AppLogoWidget(),

                    SizedBox(height: 6.h),

                    // Welcome Text
                    Text(
                      'Bienvenue',
                      textAlign: TextAlign.center,
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 20.sp,
                      ),
                    ),

                    SizedBox(height: 1.h),

                    Text(
                      'Connectez-vous pour gérer votre marché',
                      textAlign: TextAlign.center,
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                        fontSize: 14.sp,
                      ),
                    ),

                    SizedBox(height: 4.h),

                    // Error Message
                    _errorMessage != null
                        ? Container(
                            margin: EdgeInsets.only(bottom: 2.h),
                            padding: EdgeInsets.all(3.w),
                            decoration: BoxDecoration(
                              color: AppTheme.lightTheme.colorScheme.error
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(2.w),
                              border: Border.all(
                                color: AppTheme.lightTheme.colorScheme.error
                                    .withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CustomIconWidget(
                                  iconName: 'error_outline',
                                  color: AppTheme.lightTheme.colorScheme.error,
                                  size: 5.w,
                                ),
                                SizedBox(width: 3.w),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTheme
                                        .lightTheme.textTheme.bodySmall
                                        ?.copyWith(
                                      color:
                                          AppTheme.lightTheme.colorScheme.error,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),

                    // Login Form
                    LoginFormWidget(
                      onLogin: _handleLogin,
                      isLoading: _isLoading,
                    ),

                    // Biometric Authentication
                    BiometricAuthWidget(
                      onBiometricPressed: _handleBiometricAuth,
                      isAvailable: _isBiometricAvailable,
                    ),

                    SizedBox(height: 6.h),

                    // Footer Information
                    Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '© 2024 Cocody Market Manager',
                          style:
                              AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}