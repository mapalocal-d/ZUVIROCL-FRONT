import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

import '../../core/constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../core/services/storage_service.dart';
import '../../core/validators.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../data/ciudades.dart';
import 'terms_screen.dart'; // Pantalla de términos
import 'privacy_screen.dart'; // Pantalla de privacidad

// =========================================================
// PANTALLA DE REGISTRO DE CONDUCTOR
// =========================================================

class RegisterConductorScreen extends StatefulWidget {
  const RegisterConductorScreen({super.key});

  @override
  State<RegisterConductorScreen> createState() =>
      _RegisterConductorScreenState();
}

class _RegisterConductorScreenState extends State<RegisterConductorScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _storage = StorageService();

  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _patenteController = TextEditingController();

  // FocusNodes
  final _apellidoFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _regionFocus = FocusNode();
  final _ciudadFocus = FocusNode();
  final _patenteFocus = FocusNode();
  final _lineaFocus = FocusNode();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _acceptTerms = false;
  String? _errorMessage;

  // Valores seleccionados
  Map<String, String>? _selectedRegion;
  Map<String, dynamic>? _selectedCiudad;
  Map<String, String>? _selectedLinea;

  // Listas filtradas
  List<Map<String, dynamic>> _ciudadesFiltradas = [];
  List<Map<String, String>> _lineasFiltradas = [];

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
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _patenteController.dispose();
    _apellidoFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _regionFocus.dispose();
    _ciudadFocus.dispose();
    _patenteFocus.dispose();
    _lineaFocus.dispose();
    super.dispose();
  }

  // =========================================================
  // LÓGICA DE FILTRADO
  // =========================================================

  void _onRegionSelected(Map<String, String>? region) {
    setState(() {
      _selectedRegion = region;
      _selectedCiudad = null;
      _selectedLinea = null;
      _ciudadesFiltradas = [];
      _lineasFiltradas = [];

      if (region != null) {
        _ciudadesFiltradas = CIUDADES
            .where((ciudad) => ciudad['region'] == region['nombre'])
            .toList();
      }
    });
  }

  void _onCiudadSelected(Map<String, dynamic>? ciudad) {
    setState(() {
      _selectedCiudad = ciudad;
      _selectedLinea = null;
      _lineasFiltradas = [];

      if (ciudad != null) {
        final ciudadKey = normalizeCityName(ciudad['nombre'] as String);
        _lineasFiltradas =
            LINEAS_POR_CIUDAD[ciudadKey]?.cast<Map<String, String>>() ?? [];
      }
    });
  }

  // =========================================================
  // REGISTRO
  // =========================================================

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(
          () => _errorMessage = 'Debes aceptar los términos y condiciones.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final api = ApiClient(_storage);

      final response = await api.post(
        ApiConstants.registerConductor,
        data: {
          'nombre': _nombreController.text.trim(),
          'apellido': _apellidoController.text.trim(),
          'correo': _emailController.text.trim().toLowerCase(),
          'contrasena': _passwordController.text,
          'confirmar_contrasena': _confirmPasswordController.text,
          'region': _selectedRegion!['nombre']!,
          'ciudad': _selectedCiudad!['nombre']!,
          'patente': _patenteController.text.trim().toUpperCase(),
          'linea_recorrido': _selectedLinea!['id']!,
          'acepta_terminos': _acceptTerms,
        },
      );

      final data = response.data;
      final usuario = data['usuario'] as Map<String, dynamic>?;

      await _storage.saveSession(
        accessToken: data['access_token'],
        refreshToken: data['refresh_token'],
        rol: data['rol'] ?? 'conductor',
        expiresInSeconds: data['expira_en'] ?? 3600,
        usuario: usuario,
      );

      if (!mounted) return;

      _showSuccessAndNavigate(data['mensaje'] ?? 'Registro exitoso');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Error inesperado. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessAndNavigate(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(color: AppTheme.textMain),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.surface,
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        AppNavigator.toDashboard(context, 'conductor');
      }
    });
  }

  // =========================================================
  // UI
  // =========================================================

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
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildErrorBanner(),
                  _buildNombreField(),
                  const SizedBox(height: 16),
                  _buildApellidoField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 16),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 16),
                  _buildRegionDropdown(),
                  const SizedBox(height: 16),
                  _buildCiudadDropdown(),
                  const SizedBox(height: 16),
                  _buildPatenteField(),
                  const SizedBox(height: 16),
                  _buildLineaDropdown(),
                  const SizedBox(height: 24),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),
                  _buildRegisterButton(),
                  const SizedBox(height: 24),
                  _buildLoginLink(),
                  const SizedBox(height: 32),
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
            Icons.directions_bus_filled_outlined,
            color: AppTheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Registro Conductor',
          style: TextStyle(
            color: AppTheme.textMain,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Únete como conductor y ofrece tus servicios.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
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
              style: const TextStyle(color: AppTheme.error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => _errorMessage = null),
            child: const Icon(Icons.close, color: AppTheme.error, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildNombreField() {
    return TextFormField(
      controller: _nombreController,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Nombre',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) => AppValidators.validateNombrePropio(value, 'nombre'),
      onFieldSubmitted: (_) => _apellidoFocus.requestFocus(),
    );
  }

  Widget _buildApellidoField() {
    return TextFormField(
      controller: _apellidoController,
      focusNode: _apellidoFocus,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Apellido',
        prefixIcon: Icon(Icons.person_outline),
      ),
      validator: (value) =>
          AppValidators.validateNombrePropio(value, 'apellido'),
      onFieldSubmitted: (_) => _emailFocus.requestFocus(),
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      focusNode: _emailFocus,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Correo electrónico',
        prefixIcon: Icon(Icons.email_outlined),
      ),
      validator: AppValidators.validateEmail,
      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: InputDecoration(
        hintText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: AppTheme.textMuted,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ),
      validator: AppValidators.validatePassword,
      onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      focusNode: _confirmPasswordFocus,
      obscureText: _obscureConfirm,
      textInputAction: TextInputAction.next,
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
        if (value != _passwordController.text)
          return 'Las contraseñas no coinciden';
        return null;
      },
      onFieldSubmitted: (_) => _regionFocus.requestFocus(),
    );
  }

  Widget _buildRegionDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedRegion,
      focusNode: _regionFocus,
      decoration: const InputDecoration(
        labelText: 'Región',
        prefixIcon: Icon(Icons.map_outlined),
      ),
      hint: const Text('Selecciona región'),
      items: REGIONES.map((region) {
        return DropdownMenuItem<Map<String, String>>(
          value: region,
          child: Text(region['nombre']!),
        );
      }).toList(),
      onChanged: _onRegionSelected,
      validator: (value) {
        if (value == null) return 'Selecciona una región';
        return null;
      },
    );
  }

  Widget _buildCiudadDropdown() {
    return DropdownButtonFormField<Map<String, dynamic>>(
      value: _selectedCiudad,
      focusNode: _ciudadFocus,
      decoration: const InputDecoration(
        labelText: 'Ciudad',
        prefixIcon: Icon(Icons.location_city_outlined),
      ),
      hint: const Text('Selecciona ciudad'),
      items: _ciudadesFiltradas.map((ciudad) {
        return DropdownMenuItem<Map<String, dynamic>>(
          value: ciudad,
          child: Text(ciudad['nombre'] as String),
        );
      }).toList(),
      onChanged: _onCiudadSelected,
      validator: (value) {
        if (value == null) return 'Selecciona una ciudad';
        return null;
      },
    );
  }

  Widget _buildPatenteField() {
    return TextFormField(
      controller: _patenteController,
      focusNode: _patenteFocus,
      textCapitalization: TextCapitalization.characters,
      textInputAction: TextInputAction.next,
      style: const TextStyle(color: AppTheme.textMain),
      decoration: const InputDecoration(
        hintText: 'Patente (ej. AABB12)',
        prefixIcon: Icon(Icons.directions_car_outlined),
      ),
      validator: AppValidators.validatePatente,
      onFieldSubmitted: (_) => _lineaFocus.requestFocus(),
    );
  }

  Widget _buildLineaDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      value: _selectedLinea,
      focusNode: _lineaFocus,
      decoration: const InputDecoration(
        labelText: 'Línea de recorrido',
        prefixIcon: Icon(Icons.route_outlined),
      ),
      hint: const Text('Selecciona línea'),
      items: _lineasFiltradas.map((linea) {
        return DropdownMenuItem<Map<String, String>>(
          value: linea,
          child: Text(linea['nombre'] ?? linea['id']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedLinea = value);
      },
      validator: (value) {
        if (value == null) return 'Selecciona una línea';
        return null;
      },
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _acceptTerms,
            onChanged: (value) => setState(() => _acceptTerms = value ?? false),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Acepto los '),
                  TextSpan(
                    text: 'Términos y Condiciones',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TermsScreen()),
                        );
                      },
                  ),
                  const TextSpan(text: ' y la '),
                  TextSpan(
                    text: 'Política de Privacidad',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const PrivacyScreen()),
                        );
                      },
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Text('REGISTRARME COMO CONDUCTOR'),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '¿Ya tienes cuenta? ',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Inicia sesión'),
          ),
        ],
      ),
    );
  }
}
