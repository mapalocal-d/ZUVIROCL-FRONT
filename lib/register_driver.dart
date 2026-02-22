import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'secure_storage.dart';
import 'app_logger.dart';
import 'politica_legal.dart';
import 'api_config.dart';

const emeraldGreen = Color(0xFF50C878);

// Alineado al backend: Validadores.DOMINIOS_PROHIBIDOS
final Set<String> dominiosProhibidos = {
  'tempmail.com',
  '10minutemail.com',
  'guerrillamail.com',
  'throwawaymail.com',
  'mailinator.com',
  'yopmail.com',
  'sharklasers.com',
  'getairmail.com',
  'dispostable.com',
};

// Alineado al backend: Validadores.NOMBRES_RESERVADOS
final Set<String> nombresReservados = {
  'admin',
  'administrador',
  'soporte',
  'root',
  'moderador',
  'zuviro',
  'sistema',
  'test',
  'null',
  'undefined',
  'api',
  'webhook',
  'notification',
  'user',
  'usuario',
  'guest',
  'invitado',
  'support',
  'help',
  'info',
  'contact',
  'noreply',
  'no-reply',
  'postmaster',
  'hostmaster',
  'webmaster',
  'abuse',
};

// Alineado al backend: Validadores.contrasena
final Set<String> contrasenasComunes = {
  'password',
  '123456',
  '12345678',
  'qwerty',
  'abc123',
  'zuviro123',
  'password123',
  'admin123',
  'letmein',
  'welcome',
  'monkey',
  '1234567890',
  'football',
  'iloveyou',
};

final List<String> secuenciasTeclado = [
  'qwerty',
  'asdfgh',
  'zxcvbn',
  '123456',
  '654321',
];

// Alineado al backend: Validadores.patente_chilena
final RegExp patenteModerna = RegExp(r'^[A-Z]{4}[0-9]{2}$');
final RegExp patenteAntigua = RegExp(r'^[A-Z]{2}[0-9]{4}$');
final RegExp patenteMoto = RegExp(r'^[A-Z]{3}[0-9]{2}$');

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() => _RegisterDriverScreenState();
}

class _RegisterDriverScreenState extends State<RegisterDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _aceptaTerminos = false;
  bool _loading = false;
  String? _error;
  String? _emailErrorText;
  bool _checkingEmail = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  Timer? _emailDebounce;

  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _patenteController = TextEditingController();

  String? _selectedRegion;
  String? _selectedCiudad;
  String? _selectedLinea;
  List<Map<String, dynamic>> regiones = [];
  List<Map<String, dynamic>> ciudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];
  List<Map<String, dynamic>> lineas = [];
  bool _loadingCities = true;
  bool _loadingLines = false;

  @override
  void initState() {
    super.initState();
    _loadCiudadesYRegiones();
  }

  @override
  void dispose() {
    _emailDebounce?.cancel();
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _patenteController.dispose();
    super.dispose();
  }

  // ========== UTILIDADES ==========

  String normalizarCiudad(String? nombre) {
    if (nombre == null) return '';
    return nombre
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ñ', 'n');
  }

  // ========== EMAIL: CHECK BACKEND ==========

  Future<bool> emailExisteEnBackend(String email) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.checkEmail}?email=$email&rol=conductor'),
      headers: {'accept': 'application/json'},
    );
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body["disponible"] == false;
    }
    if (response.statusCode == 422) {
      return false;
    }
    throw Exception('Error consultando disponibilidad');
  }

  void _onEmailChanged(String value) {
    _emailDebounce?.cancel();
    final email = value.trim();

    if (email.isEmpty) {
      setState(() => _emailErrorText = "Ingresa tu email");
      return;
    }
    if (!_validateFormatoEmail(email)) {
      setState(() => _emailErrorText = "Formato de email inválido");
      return;
    }

    setState(() => _emailErrorText = null);

    _emailDebounce = Timer(const Duration(milliseconds: 600), () async {
      setState(() => _checkingEmail = true);
      try {
        bool exists = await emailExisteEnBackend(email);
        if (mounted) {
          setState(() {
            _emailErrorText = exists ? "Este email ya está registrado" : null;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _emailErrorText = "Error verificando email");
        }
      }
      if (mounted) setState(() => _checkingEmail = false);
    });
  }

  // ========== VALIDACIONES ALINEADAS AL BACKEND ==========

  // Backend: Validadores.nombre_propio
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    final nombre = value.trim();
    if (nombre.length < 2) return "Debe tener al menos 2 caracteres";
    if (nombre.length > 50) return "Máximo 50 caracteres";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]+$").hasMatch(nombre))
      return "Solo letras, espacios, apóstrofes y guiones";
    if (nombresReservados.contains(nombre.toLowerCase()))
      return "Nombre reservado por el sistema";
    return null;
  }

  // Backend: Validadores.nombre_propio
  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu apellido";
    final apellido = value.trim();
    if (apellido.length < 2) return "Debe tener al menos 2 caracteres";
    if (apellido.length > 50) return "Máximo 50 caracteres";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'\-]+$").hasMatch(apellido))
      return "Solo letras, espacios, apóstrofes y guiones";
    if (nombresReservados.contains(apellido.toLowerCase()))
      return "Apellido reservado por el sistema";
    return null;
  }

  // Backend: Validadores.email
  bool _validateFormatoEmail(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final email = value.trim().toLowerCase();
    if (email.contains(' ')) return false;
    if (email.length > 254) return false;
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email)) return false;

    final parts = email.split('@');
    if (parts.length != 2) return false;
    final local = parts[0];
    final dominio = parts[1];

    if (local.length > 64) return false;
    if (local.startsWith('.') || local.endsWith('.') || email.contains('..'))
      return false;
    if (local.startsWith('-') || local.endsWith('-')) return false;
    if (!RegExp(r'^[a-z0-9._%+\-]+$').hasMatch(local)) return false;

    if (dominiosProhibidos.contains(dominio)) return false;
    if (dominio.endsWith('.com.com') ||
        dominio.endsWith('.cl.cl') ||
        dominio.endsWith('.es.es') ||
        dominio.endsWith('.net.net'))
      return false;

    return true;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim();
    if (email == null || email.isEmpty) return "Ingresa tu email";
    if (!_validateFormatoEmail(email)) return "Email inválido";
    if (_emailErrorText != null) return _emailErrorText;
    return null;
  }

  // Backend: Validadores.contrasena (NIST SP 800-63B)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 128) return "Máximo 128 caracteres";
    if (value != value.trim())
      return "No debe tener espacios al inicio o final";

    int cumple = 0;
    if (RegExp(r'[A-Z]').hasMatch(value)) cumple++;
    if (RegExp(r'[a-z]').hasMatch(value)) cumple++;
    if (RegExp(r'[0-9]').hasMatch(value)) cumple++;
    if (RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) cumple++;

    if (cumple < 3)
      return "Debe contener al menos 3 de: mayúsculas, minúsculas, números y símbolos";

    if (contrasenasComunes.contains(value.toLowerCase()))
      return "Contraseña demasiado común. Elige una más única.";

    for (final seq in secuenciasTeclado) {
      if (value.toLowerCase().contains(seq))
        return "Contiene secuencias de teclado predecibles";
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != _passwordController.text)
      return "Las contraseñas no coinciden";
    return null;
  }

  // Backend: Field(..., min_length=2, max_length=50)
  String? _validateRegion(String? value) {
    if (value == null || value.isEmpty) return "Elige una región";
    if (value.length < 2) return "Debe tener al menos 2 caracteres";
    if (value.length > 50) return "Máximo 50 caracteres";
    return null;
  }

  // Backend: Field(..., min_length=2, max_length=40)
  String? _validateCiudad(String? value) {
    if (value == null || value.isEmpty) return "Elige una ciudad";
    if (value.length < 2) return "Debe tener al menos 2 caracteres";
    if (value.length > 40) return "Máximo 40 caracteres";
    return null;
  }

  // Backend: Validadores.patente_chilena
  // AABB12 (moderna 6), AA1212 (antigua 6), AAA12 (moto 5)
  String? _validatePatente(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa la patente";
    final patente = value.trim().toUpperCase().replaceAll(
      RegExp(r'[\s.\-·]'),
      '',
    );

    if (patente.length < 5 || patente.length > 6)
      return "La patente debe tener 5 o 6 caracteres";

    if (patente.length == 6) {
      if (!patenteModerna.hasMatch(patente) &&
          !patenteAntigua.hasMatch(patente))
        return "Formato inválido. Ej: AABB12 o AA1212";
    } else if (patente.length == 5) {
      if (!patenteMoto.hasMatch(patente))
        return "Formato inválido. Ej: AAA12 (moto)";
    }

    return null;
  }

  // Backend: Field(..., min_length=1, max_length=10)
  String? _validateLinea(String? value) {
    if (value == null || value.isEmpty) return "Elige una línea o recorrido";
    if (value.length > 10) return "Máximo 10 caracteres";
    return null;
  }

  // ========== CARGAR DATOS ==========

  Future<void> _loadCiudadesYRegiones() async {
    try {
      final resp = await http.get(Uri.parse(ApiConfig.configCiudades));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          regiones = List<Map<String, dynamic>>.from(data['regiones']);
          ciudades = List<Map<String, dynamic>>.from(data['ciudades']);
          ciudadesFiltradas = ciudades;
          _loadingCities = false;
        });
      } else {
        setState(() {
          regiones = [];
          ciudades = [];
          ciudadesFiltradas = [];
          _loadingCities = false;
        });
      }
    } catch (_) {
      setState(() {
        regiones = [];
        ciudades = [];
        ciudadesFiltradas = [];
        _loadingCities = false;
      });
    }
  }

  Future<void> _loadLineas(String ciudad) async {
    setState(() {
      _loadingLines = true;
      lineas = [];
      _selectedLinea = null;
    });
    final ciudadNormalizada = normalizarCiudad(ciudad);
    try {
      final resp = await http.get(
        Uri.parse(
          '${ApiConfig.configLineas}?ciudad=${Uri.encodeComponent(ciudadNormalizada)}',
        ),
      );
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          lineas = List<Map<String, dynamic>>.from(data['lineas'] ?? []);
          _loadingLines = false;
        });
      } else {
        setState(() {
          lineas = [];
          _loadingLines = false;
        });
      }
    } catch (_) {
      setState(() {
        lineas = [];
        _loadingLines = false;
      });
    }
  }

  // ========== REGISTRO ==========

  Future<void> _registerDriver() async {
    if (!_formKey.currentState!.validate() || !_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Completa todos los campos y acepta los términos."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final url = Uri.parse(ApiConfig.registerConductor);
    final body = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "correo": _emailController.text.trim(),
      "contrasena": _passwordController.text,
      "confirmar_contrasena": _confirmPasswordController.text,
      "region": _selectedRegion,
      "ciudad": _selectedCiudad,
      "patente": _patenteController.text.trim().toUpperCase().replaceAll(
        RegExp(r'[\s.\-·]'),
        '',
      ),
      "linea_recorrido": _selectedLinea,
      "acepta_terminos": _aceptaTerminos,
    };

    try {
      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );
      final messenger = ScaffoldMessenger.of(context);
      if (resp.statusCode == 201) {
        final respBody = json.decode(resp.body);
        final accessToken = respBody['access_token'];
        final refreshToken = respBody['refresh_token'];
        if (accessToken != null) {
          final secure = SecureStorage();
          await secure.setAccessToken(accessToken);
          if (refreshToken != null) {
            await secure.setRefreshToken(refreshToken);
          }
          await secure.setRol('conductor');

          final usuario = respBody['usuario'];
          if (usuario != null) {
            await secure.guardarDatosUsuario(usuario);
          }
        }
        AppLogger.i('Registro conductor exitoso.');
        messenger.showSnackBar(
          const SnackBar(
            content: Text("¡Registro exitoso! Bienvenido conductor."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/dashboard_conductor');
        }
      } else {
        final respBody = json.decode(resp.body);
        setState(() {
          _error =
              (respBody['detail'] ?? "Registro fallido. Intenta nuevamente.")
                  .toString();
        });
        AppLogger.w('Registro conductor falló: $_error');
        messenger.showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e, s) {
      AppLogger.e('Error en registro conductor', e, s);
      setState(() => _error = "Error de conexión");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Registro Conductor', style: TextStyle(fontSize: 20)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.blue,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(_nombreController, 'Nombre', _validateNombre),
              _buildField(_apellidoController, 'Apellido', _validateApellido),
              _buildField(
                _emailController,
                'Email',
                _validateEmail,
                helper: "Debe ser válido (ejemplo@correo.com)",
                keyboardType: TextInputType.emailAddress,
                errorText: _emailErrorText,
                onChanged: _onEmailChanged,
              ),
              if (_checkingEmail)
                const Padding(
                  padding: EdgeInsets.only(left: 10, top: 3, bottom: 3),
                  child: LinearProgressIndicator(),
                ),
              _buildField(
                _passwordController,
                'Contraseña',
                _validatePassword,
                obscure: !_showPassword,
                helper:
                    "8-128 caracteres. Al menos 3 de: mayúsculas, minúsculas, números y símbolos.",
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() => _showPassword = !_showPassword);
                  },
                ),
              ),
              _buildField(
                _confirmPasswordController,
                'Confirmar contraseña',
                _validateConfirmPassword,
                obscure: !_showConfirmPassword,
                helper: "Debe coincidir con tu contraseña.",
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(
                      () => _showConfirmPassword = !_showConfirmPassword,
                    );
                  },
                ),
              ),
              // Región
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: const InputDecoration(
                        labelText: "Región",
                        labelStyle: TextStyle(color: Colors.blue, fontSize: 15),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 2),
                        ),
                      ),
                      validator: _validateRegion,
                      items: regiones.map((reg) {
                        return DropdownMenuItem<String>(
                          value: reg['nombre'],
                          child: Text(
                            reg['nombre'],
                            style: const TextStyle(color: Colors.blue),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRegion = val;
                          _selectedCiudad = null;
                          _selectedLinea = null;
                          ciudadesFiltradas = ciudades
                              .where((c) => c['region'] == val)
                              .toList();
                          lineas = [];
                        });
                      },
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      "Ejemplo: Antofagasta, Atacama, Coquimbo.",
                      style: TextStyle(color: emeraldGreen, fontSize: 13.5),
                    ),
                  ],
                ),
              ),
              // Ciudad
              _loadingCities
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedCiudad,
                            decoration: const InputDecoration(
                              labelText: "Ciudad",
                              labelStyle: TextStyle(
                                color: Colors.blue,
                                fontSize: 15,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: _validateCiudad,
                            items: ciudadesFiltradas.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['nombre'],
                                child: Text(
                                  c['nombre'],
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                _selectedCiudad = val;
                                _selectedLinea = null;
                                lineas = [];
                                _loadingLines = true;
                              });
                              if (val != null) {
                                _loadLineas(val);
                              }
                            },
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Elige la ciudad donde vas a trabajar como conductor.",
                            style: TextStyle(
                              color: emeraldGreen,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
              // Patente
              _buildField(
                _patenteController,
                'Patente',
                _validatePatente,
                textCapitalization: TextCapitalization.characters,
                helper:
                    "Formatos: AABB12 (moderna), AA1212 (antigua), AAA12 (moto)",
              ),
              // Línea
              _selectedCiudad == null
                  ? const SizedBox()
                  : _loadingLines
                  ? const Padding(
                      padding: EdgeInsets.all(8),
                      child: LinearProgressIndicator(),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedLinea,
                            decoration: const InputDecoration(
                              labelText: "Línea o recorrido",
                              labelStyle: TextStyle(
                                color: Colors.blue,
                                fontSize: 15,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: _validateLinea,
                            items: lineas.map((l) {
                              final descripcion =
                                  l['descripcion'] != null &&
                                      l['descripcion'].toString().isNotEmpty
                                  ? ' (${l['descripcion']})'
                                  : '';
                              return DropdownMenuItem<String>(
                                value: l['nombre'],
                                child: Text(
                                  "${l['nombre']}$descripcion",
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedLinea = val),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Selecciona la línea o recorrido del colectivo en tu ciudad.",
                            style: TextStyle(
                              color: emeraldGreen,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 12),
              // Términos
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                    activeColor: Colors.blue,
                    checkColor: Colors.black,
                  ),
                  Expanded(
                    child: Wrap(
                      children: [
                        const Text(
                          'Acepto los ',
                          style: TextStyle(color: Colors.blue, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PoliticaLegalScreen(),
                            ),
                          ),
                          child: const Text(
                            'términos y condiciones y política de privacidad',
                            style: TextStyle(
                              color: Color(0xFF50C878),
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!_aceptaTerminos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debes aceptar los términos y condiciones para registrarte.',
                    style: TextStyle(color: Colors.red, fontSize: 13.5),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 9),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: _loading ? null : _registerDriver,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text("Registrarse"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    String? Function(String?) validator, {
    String? helper,
    bool obscure = false,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? errorText,
    Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.blue, fontSize: 15),
          enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 1),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 11,
          ),
          helperText: helper,
          errorText: errorText,
          helperStyle: helper != null
              ? const TextStyle(color: emeraldGreen, fontSize: 13.5)
              : null,
          suffixIcon: suffixIcon,
        ),
        style: const TextStyle(color: Colors.blue, fontSize: 15),
        obscureText: obscure,
        validator: validator,
        textInputAction: TextInputAction.next,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        onChanged: onChanged,
      ),
    );
  }
}
