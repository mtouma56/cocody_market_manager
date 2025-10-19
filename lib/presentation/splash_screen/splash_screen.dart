import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;
  String _loadingText = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
    ));

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Set system UI overlay style
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: AppTheme.primaryGreen,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarColor: AppTheme.primaryGreen,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

      // Simulate initialization tasks
      await _performInitializationTasks();

      // Wait for animation to complete
      await _animationController.forward();
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        _handleInitializationError();
      }
    }
  }

  Future<void> _performInitializationTasks() async {
    // Task 1: Check authentication status
    setState(() => _loadingText = 'Vérification de l\'authentification...');
    await Future.delayed(const Duration(milliseconds: 800));

    // Task 2: Load cached property data
    setState(() => _loadingText = 'Chargement des données...');
    await Future.delayed(const Duration(milliseconds: 600));

    // Task 3: Sync with backend
    setState(() => _loadingText = 'Synchronisation...');
    await Future.delayed(const Duration(milliseconds: 700));

    // Task 4: Prepare offline functionality
    setState(() => _loadingText = 'Préparation du mode hors ligne...');
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _loadingText = 'Prêt !';
      _isInitialized = true;
    });
  }

  void _navigateToNextScreen() {
    // Check if user is authenticated (mock logic)
    final bool isAuthenticated = _checkAuthenticationStatus();

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/dashboard-screen');
    } else {
      Navigator.pushReplacementNamed(context, '/login-screen');
    }
  }

  bool _checkAuthenticationStatus() {
    // Mock authentication check
    // In real implementation, this would check stored tokens/credentials
    return false; // Default to not authenticated for demo
  }

  void _handleInitializationError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Erreur d\'initialisation',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          'Une erreur s\'est produite lors du démarrage de l\'application. Veuillez réessayer.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _retryInitialization();
            },
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _retryInitialization() {
    setState(() {
      _isInitialized = false;
      _loadingText = 'Initialisation...';
    });
    _animationController.reset();
    _animationController.forward();
    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryGreen,
              AppTheme.successAccent,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 3,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Opacity(
                          opacity: _fadeAnimation.value,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildLogo(),
                              SizedBox(height: 3.h),
                              _buildAppTitle(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLoadingIndicator(),
                    SizedBox(height: 2.h),
                    _buildLoadingText(),
                  ],
                ),
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neutralDark.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'store',
              color: AppTheme.primaryGreen,
              size: 8.w,
            ),
            SizedBox(height: 1.h),
            Text(
              'MCM',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Column(
      children: [
        Text(
          'Marché Cocody',
          style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
            color: AppTheme.surfaceWhite,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 0.5.h),
        Text(
          'Saint Jean',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: AppTheme.surfaceWhite.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
            fontSize: 16.sp,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 1.h),
        Text(
          'Gestionnaire de Location',
          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.surfaceWhite.withValues(alpha: 0.8),
            fontSize: 12.sp,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 6.w,
      height: 6.w,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          AppTheme.surfaceWhite.withValues(alpha: 0.9),
        ),
        backgroundColor: AppTheme.surfaceWhite.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildLoadingText() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        _loadingText,
        key: ValueKey(_loadingText),
        style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.surfaceWhite.withValues(alpha: 0.9),
          fontSize: 11.sp,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
