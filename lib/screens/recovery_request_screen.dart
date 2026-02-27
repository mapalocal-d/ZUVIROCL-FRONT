import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/storage_service.dart';
import '../../core/validators.dart';
import '../../theme/app_theme.dart';
import 'recovery_confirm_screen.dart';

class RecoveryRequestScreen extends StatefulWidget {
  const RecoveryRequestScreen({super.key});

  @override
  State<RecoveryRequestScreen> createState() => _RecoveryRequestScreenState();
}

class _RecoveryRequestScreenState extends State<RecoveryRequestScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _storage = StorageService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
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
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient(_storage);
      final response = await api.post(
        '${ApiConstants.recuperarSolicitar}?rol=${_selectedRole.toJson()}',
        data: {'correo': _emailController.text.trim().toLowerCase()},
      );

      // El backend siempre responde con mensaje genérico
      final mensaje = response.data['mensaje'] ??
          'Si el correo existe, recibirás un código de recuperación';

      // Mostrar mensaje y luego navegar a la pantalla de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensaje),
          backgroundColor: AppTheme.success,
          duration: const Duration(seconds: 3),
        ),
      );

      // Navegar a la pantalla de confirmación pasando el correo y rol
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RecoveryConfirmScreen(
                email: _emailController.text.trim().toLowerCase(),
                role: _selectedRole,
              ),
            ),
          );
        }
      });
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.textMain),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recuperar contraseña',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildRoleSelector(),
                  const SizedBox(height: 20),
                  _buildEmailField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildInfoMessage(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.lock_reset_outlined,
            color: AppTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          '¿Olvidaste tu contraseña?',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa tu correo y selecciona tu tipo de cuenta. Te enviaremos un código de verificación.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
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
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: AppValidators.validateEmail,
      onFieldSubmitted: (_) => _solicitar(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _solicitar,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('ENVIAR CÓDIGO'),
      ),
    );
  }

  Widget _buildInfoMessage() {
    if (_errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
        ),
        child: Text(
          _errorMessage!,
          style: const TextStyle(color: AppTheme.error, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// Widget auxiliar para botones de rol (igual que en LoginScreen)
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
