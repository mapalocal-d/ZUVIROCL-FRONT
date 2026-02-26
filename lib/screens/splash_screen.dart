import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/services/storage_service.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final _storage = StorageService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  String _statusText = '';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    // Animación de entrada: logo fade + scale
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animController.forward();

    // Esperar animación mínima + verificar sesión
    _checkSessionAfterDelay();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // =========================================================
  // LÓGICA DE SESIÓN
  // =========================================================

  Future<void> _checkSessionAfterDelay() async {
    // Mostrar splash mínimo 1.5s para que se vea el logo
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final status = await _storage.checkSession();

    switch (status) {
      case SessionStatus.valid:
        _navigateToDashboard();
        break;

      case SessionStatus.needsRefresh:
        await _attemptTokenRefresh();
        break;

      case SessionStatus.expired:
        _navigateToLogin();
        break;
    }
  }

  Future<void> _attemptTokenRefresh() async {
    setState(() => _statusText = 'Restaurando sesión...');

    try {
      final api = ApiClient(_storage);
      final refreshToken = await _storage.getRefreshToken();

      if (refreshToken == null) {
        _navigateToLogin();
        return;
      }

      final response = await api.post(
        ApiConstants.refresh,
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccess = data['access_token'] as String?;
      final newRefresh = data['refresh_token'] as String?;
      final expiresIn = data['expira_en'] as int?;

      if (newAccess == null || newRefresh == null || expiresIn == null) {
        _navigateToLogin();
        return;
      }

      await _storage.updateTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
        expiresInSeconds: expiresIn,
      );

      if (!mounted) return;
      _navigateToDashboard();
    } on ApiException catch (_) {
      if (!mounted) return;
      _navigateToLogin();
    } catch (_) {
      if (!mounted) return;
      // Error de red — dar opción de reintentar
      setState(() {
        _hasError = true;
        _statusText = 'Sin conexión a internet';
      });
    }
  }

  // =========================================================
  // NAVEGACIÓN
  // =========================================================

  void _navigateToDashboard() {
    final rol = _storage.userRole.toJson();
    AppNavigator.toDashboard(context, rol);
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),

            // Logo animado
            FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: _buildLogo(),
              ),
            ),

            const SizedBox(height: 48),

            // Indicador de carga o error
            _hasError ? _buildErrorState() : _buildLoadingState(),

            const Spacer(flex: 4),

            // Versión
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text(
                'v1.0.0',
                style: TextStyle(
                  color: AppTheme.textHint,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icono principal
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
            boxShadow: AppTheme.primaryGlow,
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            size: 48,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),

        // Nombre de la app
        Text(
          'ZUVIRO',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        Text(
          'Tu transporte, más cerca',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppTheme.primary,
          ),
        ),
        if (_statusText.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _statusText,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 13,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.wifi_off_rounded,
          color: AppTheme.error,
          size: 32,
        ),
        const SizedBox(height: 12),
        Text(
          _statusText,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: 180,
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _hasError = false;
                _statusText = '';
              });
              _checkSessionAfterDelay();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}
