import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/enums.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/storage_service.dart';
import '../../core/validators.dart';
import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';

class RecoveryConfirmScreen extends StatefulWidget {
  final String email;
  final UserRole role;

  const RecoveryConfirmScreen({
    super.key,
    required this.email,
    required this.role,
  });

  @override
  State<RecoveryConfirmScreen> createState() => _RecoveryConfirmScreenState();
}

class _RecoveryConfirmScreenState extends State<RecoveryConfirmScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storage = StorageService();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  bool _success = false;

  // Contador para reenviar código
  int _resendCooldown = 60;
  bool _canResend = false;

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

    _startResendCooldown();
  }

  void _startResendCooldown() {
    _canResend = false;
    _resendCooldown = 60;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          _canResend = true;
        }
      });
      return _resendCooldown > 0 && mounted;
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient(_storage);
      final response = await api.post(
        '${ApiConstants.recuperarConfirmar}?rol=${widget.role.toJson()}',
        data: {
          'correo': widget.email,
          'codigo': _codeController.text.trim(),
          'nueva_contrasena': _newPasswordController.text,
          'confirmar_contrasena': _confirmPasswordController.text,
        },
      );

      setState(() => _success = true);

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  response.data['mensaje'] ?? 'Contraseña actualizada',
                  style: const TextStyle(color: AppTheme.textMain),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.surface,
          duration: const Duration(seconds: 3),
        ),
      );

      // Redirigir al login después de un breve delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
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

  Future<void> _reenviarCodigo() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient(_storage);
      await api.post(
        '${ApiConstants.recuperarSolicitar}?rol=${widget.role.toJson()}',
        data: {'correo': widget.email},
      );

      // Reiniciar contador
      _startResendCooldown();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código reenviado. Revisa tu correo.'),
          backgroundColor: AppTheme.success,
        ),
      );
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Error al reenviar código.');
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
          'Nueva contraseña',
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
                  _buildEmailInfo(),
                  const SizedBox(height: 20),
                  _buildCodeField(),
                  const SizedBox(height: 20),
                  _buildNewPasswordField(),
                  const SizedBox(height: 20),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 24),
                  _buildResendButton(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 24),
                  _buildErrorMessage(),
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
            Icons.lock_outline,
            color: AppTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Establece tu nueva contraseña',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ingresa el código que enviamos a tu correo y tu nueva contraseña.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.email_outlined, color: AppTheme.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Correo',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.email,
                  style: const TextStyle(
                    color: AppTheme.textMain,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return TextFormField(
      controller: _codeController,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      maxLength: 6,
      decoration: InputDecoration(
        hintText: 'Código de 6 dígitos',
        prefixIcon: const Icon(Icons.pin_outlined),
        counterText: '',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'El código es requerido';
        }
        if (value.length != 6) {
          return 'El código debe tener 6 dígitos';
        }
        if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
          return 'Solo dígitos numéricos';
        }
        return null;
      },
    );
  }

  Widget _buildNewPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscureNew,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        hintText: 'Nueva contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureNew ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted,
          ),
          onPressed: () => setState(() => _obscureNew = !_obscureNew),
        ),
      ),
      validator: AppValidators.validatePassword,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.done,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        hintText: 'Confirmar contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted,
          ),
          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Confirma tu contraseña';
        if (value != _newPasswordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
      onFieldSubmitted: (_) => _confirmar(),
    );
  }

  Widget _buildResendButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No recibiste el código? ',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        if (_canResend)
          TextButton(
            onPressed: _reenviarCodigo,
            child: const Text('Reenviar'),
          )
        else
          Text(
            'Reenviar en $_resendCooldown s',
            style: const TextStyle(color: AppTheme.textHint),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmar,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('CAMBIAR CONTRASEÑA'),
      ),
    );
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
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
}
