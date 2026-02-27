import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:device_info_plus/device_info_plus.dart';

import '../core/constants.dart';
import '../core/enums.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/services/storage_service.dart';
import '../core/validators.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import 'support_screen.dart'; // Importar la nueva pantalla de soporte

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storage = StorageService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  UserRole _selectedRole = UserRole.pasajero;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final deviceInfo = await _getDeviceInfo();
      final api = ApiClient(_storage);

      final response = await api.post(
        ApiConstants.login,
        data: {
          'correo': _emailController.text.trim().toLowerCase(),
          'contrasena': _passwordController.text,
          'rol': _selectedRole.toJson(),
          ...deviceInfo,
        },
      );

      final data = response.data;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      await _storage.saveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        rol: data['rol'],
        expiresInSeconds: data['expira_en'],
        usuario: usuario,
      );

      if (!mounted) return;
      AppNavigator.toDashboard(context, data['rol']);
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Obtiene información del dispositivo para enviar en el login.
  /// En caso de error, devuelve valores por defecto ('web' para el tipo).
  Future<Map<String, String>> _getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String tipo;
      String modelo;
      String id;

      if (Platform.isAndroid) {
        final android = await deviceInfo.androidInfo;
        tipo = 'android';
        modelo = '${android.manufacturer} ${android.model}';
        id = android.id;
      } else if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        tipo = 'ios';
        modelo = '${ios.name} ${ios.model}';
        id = ios.identifierForVendor ?? 'unknown';
      } else {
        // Para otras plataformas (web, desktop) usamos 'web' que es válido en el enum
        tipo = 'web';
        modelo = 'Unknown Device';
        id = 'unknown';
      }

      return {
        'dispositivo_tipo': tipo,
        'dispositivo_modelo': modelo,
        'dispositivo_id': id,
      };
    } catch (e) {
      // Si falla la obtención de información, devolvemos valores seguros
      return {
        'dispositivo_tipo': 'web',
        'dispositivo_modelo': 'Unknown',
        'dispositivo_id': 'unknown',
      };
    }
  }

  // =========================================================
  // NAVEGACIÓN
  // =========================================================

  void _showRoleSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Cómo quieres usar Zuviro?',
              style: TextStyle(
                color: AppTheme.textMain,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecciona tu tipo de cuenta',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            _RoleOption(
              icon: Icons.person_outline,
              title: 'Pasajero',
              subtitle: 'Busca y viaja en transporte público',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.registerPasajero);
              },
            ),
            const SizedBox(height: 16),
            _RoleOption(
              icon: Icons.directions_bus_filled_outlined,
              title: 'Conductor',
              subtitle: 'Ofrece tus servicios de transporte',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.registerConductor);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _goToRecovery() {
    Navigator.pushNamed(context, AppRoutes.recuperarContrasena);
  }

  void _contactSupport() {
    // Ahora navega a la pantalla de soporte en lugar de mostrar un diálogo
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  _buildLogo(),
                  const SizedBox(height: 40),
                  _buildErrorBanner(),
                  _buildRoleSelector(),
                  const SizedBox(height: 20),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 12),
                  _buildForgotPassword(),
                  const SizedBox(height: 32),
                  _buildLoginButton(),
                  const SizedBox(height: 32),
                  _buildDivider(),
                  const SizedBox(height: 24),
                  _buildCreateAccount(),
                  const SizedBox(height: 40),
                  _buildSupportButton(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // LOGO CON SVG
  // =========================================================

  Widget _buildLogo() {
    return Column(
      children: [
        SvgPicture.asset(
          'assets/mapa_demo_actualizado.svg',
          width: 120,
          height: 120,
        ),
        const SizedBox(height: 24),
        const Text(
          'ZUVIRO',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tu transporte, más cerca',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppTheme.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleButton(
              icon: Icons.person_outline,
              label: 'Pasajero',
              isSelected: _selectedRole == UserRole.pasajero,
              onTap: () => setState(() => _selectedRole = UserRole.pasajero),
            ),
          ),
          Expanded(
            child: _RoleButton(
              icon: Icons.directions_bus_filled_outlined,
              label: 'Conductor',
              isSelected: _selectedRole == UserRole.conductor,
              onTap: () => setState(() => _selectedRole = UserRole.conductor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: AppValidators.validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: AppValidators.validatePassword,
      onFieldSubmitted: (_) => _login(),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _goToRecovery,
        child: const Text('¿Olvidaste tu contraseña?'),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('INICIAR SESIÓN'),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'o',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppTheme.divider)),
      ],
    );
  }

  Widget _buildCreateAccount() {
    return Column(
      children: [
        const Text(
          '¿No tienes cuenta?',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: _showRoleSelection,
            child: const Text('CREAR CUENTA'),
          ),
        ),
      ],
    );
  }

  Widget _buildSupportButton() {
    return TextButton.icon(
      onPressed: _contactSupport,
      icon: const Icon(Icons.headset_mic_outlined, size: 18),
      label: const Text('Soporte'),
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.textMuted,
      ),
    );
  }
}

// =========================================================
// WIDGETS AUXILIARES
// =========================================================

class _RoleButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.15) : null,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppTheme.primary, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primary : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textMain,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
