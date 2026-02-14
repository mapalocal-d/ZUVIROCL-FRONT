import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

const emeraldGreen = Color(0xFF50C878);

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

  // Controladores
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _patenteController = TextEditingController();

  // Selectores
  String? _selectedRegion;
  String? _selectedCiudad;
  String? _selectedLinea;
  List<Map<String, dynamic>> regiones = [];
  List<Map<String, dynamic>> ciudades = [];
  List<Map<String, dynamic>> ciudadesFiltradas = [];
  List<Map<String, dynamic>> lineas = [];
  bool _loadingCities = true;
  bool _loadingLines = false;

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

  // ----- Validadores -----
  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu nombre";
    final nombre = value.trim();
    if (nombre.length < 2) return "Debe tener al menos 2 letras";
    if (nombre.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(nombre))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(nombre.toLowerCase()))
      return "Nombre reservado por el sistema";
    return null;
  }

  String? _validateApellido(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu apellido";
    final apellido = value.trim();
    if (apellido.length < 2) return "Debe tener al menos 2 letras";
    if (apellido.length > 50) return "Máx 50 letras";
    if (!RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$").hasMatch(apellido))
      return "Solo letras y espacios";
    final prohibidos = [
      "admin",
      "administrador",
      "soporte",
      "root",
      "moderador",
      "appcl",
    ];
    if (prohibidos.contains(apellido.toLowerCase()))
      return "Apellido reservado por el sistema";
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa tu email";
    final email = value.trim().toLowerCase();
    if (email.contains(' '))
      return "El correo electrónico no puede contener espacios.";
    if (!email.contains('@')) return "Formato de email inválido";
    final parts = email.split('@');
    if (parts.length != 2) return "Email inválido (debe tener solo un @)";
    final parte_local = parts[0];
    final dominio = parts[1];
    if (dominio.endsWith('.com.com') ||
        dominio.endsWith('.cl.cl') ||
        dominio.endsWith('.es.es'))
      return "Dominio de email inválido. Verifica que esté escrito correctamente.";
    if (email.contains('..'))
      return "Email no puede contener puntos consecutivos.";
    if (parte_local.startsWith('.') || parte_local.endsWith('.'))
      return "La parte antes del @ no puede empezar ni terminar con punto.";
    if (!RegExp(r"^[^@\s]+@[^@\s]+\.[^@\s]+$").hasMatch(email))
      return "Email inválido";
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Ingresa una contraseña";
    if (value.length < 8) return "Mínimo 8 caracteres";
    if (value.length > 32) return "Máximo 32 caracteres";
    if (!RegExp(r'[A-Z]').hasMatch(value))
      return "La contraseña debe contener al menos una letra mayúscula";
    if (!RegExp(r'\d').hasMatch(value))
      return "La contraseña debe contener al menos un número";
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value != _passwordController.text)
      return "Las contraseñas no coinciden";
    return null;
  }

  String? _validateRegion(String? value) {
    if (value == null || value.isEmpty) return "Elige una región";
    return null;
  }

  String? _validateCiudad(String? value) {
    if (value == null || value.isEmpty) return "Elige una ciudad";
    return null;
  }

  String? _validatePatente(String? value) {
    if (value == null || value.trim().isEmpty) return "Ingresa la patente";
    final patente = value.trim().toUpperCase().replaceAll(' ', '');
    if (patente.length < 6 || patente.length > 10)
      return "Debe tener de 6 a 10 caracteres";
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(patente))
      return "Solo letras mayúsculas y números";
    return null;
  }

  String? _validateLinea(String? value) {
    if (value == null || value.isEmpty) return "Elige una línea o recorrido";
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadCiudadesYRegiones();
  }

  Future<void> _loadCiudadesYRegiones() async {
    try {
      final resp = await http.get(
        Uri.parse(
          'https://graceful-balance-production-ef1d.up.railway.app/config/cities',
        ),
      );
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
          'https://graceful-balance-production-ef1d.up.railway.app/config/lines?ciudad=${Uri.encodeComponent(ciudadNormalizada)}',
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

    final url = Uri.parse(
      'https://graceful-balance-production-ef1d.up.railway.app/register/conductor',
    );
    final body = {
      "nombre": _nombreController.text.trim(),
      "apellido": _apellidoController.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text,
      "confirm_password": _confirmPasswordController.text,
      "region": _selectedRegion,
      "ciudad": _selectedCiudad,
      "patente": _patenteController.text.trim().toUpperCase().replaceAll(
        ' ',
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
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', accessToken);
        }

        messenger.showSnackBar(
          const SnackBar(
            content: Text("¡Registro exitoso! Bienvenido conductor."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          // NAVEGA AL DASHBOARD DE CONDUCTOR POR RUTA:
          Navigator.pushReplacementNamed(context, '/dashboard_conductor');
        }
      } else {
        final respBody = json.decode(resp.body);

        setState(() {
          _error =
              (respBody['detail'] ?? "Registro fallido. Intenta nuevamente.")
                  .toString();
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text(_error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Error de conexión";
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error de conexión."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

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
              ),
              _buildField(
                _passwordController,
                'Contraseña',
                _validatePassword,
                obscure: true,
                helper:
                    "Debe tener entre 8 y 32 caracteres, al menos una mayúscula y un número.",
              ),
              _buildField(
                _confirmPasswordController,
                'Confirmar contraseña',
                _validateConfirmPassword,
                obscure: true,
                helper: "Debe coincidir con tu contraseña.",
              ),

              // --- Región Selector (con ayuda en verde) ---
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedRegion,
                      decoration: InputDecoration(
                        labelText: "Región",
                        labelStyle: const TextStyle(
                          color: Colors.blue,
                          fontSize: 15,
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.blue, width: 1),
                        ),
                        focusedBorder: const OutlineInputBorder(
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
              // --- Ciudad Selector (con ayuda en verde) ---
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
                            decoration: InputDecoration(
                              labelText: "Ciudad",
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontSize: 15,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
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
              // --- Patente ---
              _buildField(
                _patenteController,
                'Patente',
                _validatePatente,
                textCapitalization: TextCapitalization.characters,
                helper: "Solo letras mayúsculas y números",
              ),
              // --- Líneas Selector (con ayuda en verde) ---
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
                            decoration: InputDecoration(
                              labelText: "Línea o recorrido",
                              labelStyle: const TextStyle(
                                color: Colors.blue,
                                fontSize: 15,
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.blue,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
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
              Row(
                children: [
                  Checkbox(
                    value: _aceptaTerminos,
                    onChanged: (value) =>
                        setState(() => _aceptaTerminos = value ?? false),
                    activeColor: Colors.blue,
                    checkColor: Colors.black,
                  ),
                  const Expanded(
                    child: Text(
                      'Acepto los términos y condiciones',
                      style: TextStyle(color: Colors.blue, fontSize: 14),
                      softWrap: true,
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
          helperStyle: helper != null
              ? const TextStyle(color: emeraldGreen, fontSize: 13.5)
              : null,
        ),
        style: const TextStyle(color: Colors.blue, fontSize: 15),
        obscureText: obscure,
        validator: validator,
        textInputAction: TextInputAction.next,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
      ),
    );
  }
}
