import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'perfil_pasajero.dart';
import 'logout_button.dart';
import 'pagar_suscripcion_pasajero.dart';
import 'estado_suscripcion_pasajero.dart';
import 'historial_pago_pasajero.dart';
import 'ayuda_soporte.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:diacritic/diacritic.dart';
import 'api_config.dart';

class DashboardPasajero extends StatefulWidget {
  const DashboardPasajero({Key? key}) : super(key: key);

  @override
  State<DashboardPasajero> createState() => _DashboardPasajeroState();
}

class _DashboardPasajeroState extends State<DashboardPasajero> {
  late Future<Map<String, String>> _datosUsuarioFuture;
  Position? _userPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _loadingLocation = true;
  String? _locationError;
  String? _networkError;
  bool _buscandoConductores = false;

  List<dynamic> _regiones = [];
  List<dynamic> _ciudades = [];

  final Map<String, Color> _coloresRegion = {
    'II': const Color(0xFF1565C0),
    'III': const Color(0xFF2E7D32),
    'IV': const Color(0xFF6A1B9A),
    'V': const Color(0xFFC62828),
    'VI': const Color(0xFFEF6C00),
    'VII': const Color(0xFF00695C),
    'VIII': const Color(0xFFAD1457),
    'IX': const Color(0xFF4527A0),
    'X': const Color(0xFF263238),
    'XI': const Color(0xFF3E2723),
    'XII': const Color(0xFF0D47A1),
    'RM': const Color(0xFFB71C1C),
    'XIV': const Color(0xFF1B5E20),
    'XV': const Color(0xFF4A148C),
    'XVI': const Color(0xFF827717),
  };

  static const Duration _timeout = Duration(seconds: 15);

  @override
  void initState() {
    super.initState();
    _datosUsuarioFuture = _getNombreEmail();
    _loadCurrentLocation();
    _cargarConfiguracion();
  }

  // ========== UTILIDADES ==========

  String _normalizarCiudad(String ciudad) {
    return removeDiacritics(ciudad).toLowerCase().trim();
  }

  // ========== CONFIGURACIÓN ==========

  Future<void> _cargarConfiguracion() async {
    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.configCiudades),
            headers: {'Accept': 'application/json'},
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _regiones = data['regiones'] ?? [];
          _ciudades = data['ciudades'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error cargando configuración: $e');
    }
  }

  Future<List<dynamic>> _cargarLineas(String ciudad) async {
    try {
      final ciudadNormalizada = _normalizarCiudad(ciudad);

      final uri = Uri.parse(
        ApiConfig.configLineas,
      ).replace(queryParameters: {'ciudad': ciudadNormalizada});

      debugPrint('Cargando líneas para ciudad: $ciudadNormalizada');

      final response = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final lineas = data['lineas'] ?? [];
        debugPrint('Líneas encontradas: ${lineas.length}');
        return lineas;
      } else {
        debugPrint('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error cargando líneas: $e');
    }
    return [];
  }

  // ========== UBICACIÓN ==========

  Future<void> _loadCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              "Permiso de ubicación denegado. Por favor, permite el acceso desde Ajustes.";
        });
        _mostrarMensaje("Permiso de ubicación denegado.");
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              "Permiso de ubicación denegado permanentemente. Habilítalo desde Ajustes para ver el mapa.";
        });
        _mostrarMensaje(
          "Debes habilitar el permiso de ubicación desde Ajustes.",
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _loadingLocation = false;
        _locationError = null;
        _actualizarMarcadorUsuario();
      });
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationError = "No se pudo obtener la ubicación. Intenta de nuevo.";
      });
      _mostrarMensaje("No se pudo obtener la ubicación.");
    }
  }

  void _actualizarMarcadorUsuario() {
    if (_userPosition == null) return;

    final marcadorUsuario = Marker(
      markerId: const MarkerId('yo'),
      position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
      infoWindow: const InfoWindow(title: 'Mi ubicación'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    );

    setState(() {
      _markers = {
        marcadorUsuario,
        ..._markers.where((m) => m.markerId.value != 'yo'),
      };
    });
  }

  // ========== BÚSQUEDA DE CONDUCTORES ==========

  void _mostrarBuscadorConductores() {
    String? regionSeleccionada;
    String? ciudadSeleccionada;
    String? lineaSeleccionada;
    List<dynamic> ciudadesFiltradas = [];
    List<dynamic> lineasDisponibles = [];
    bool cargandoLineas = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      const Text(
                        'Buscar Colectivo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selecciona tu ubicación y la línea que necesitas',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Selector de Región
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Región',
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        value: regionSeleccionada,
                        hint: const Text('Selecciona una región'),
                        items: _regiones.map<DropdownMenuItem<String>>((
                          region,
                        ) {
                          final color =
                              _coloresRegion[region['codigo']] ??
                              const Color(0xFF424242);

                          return DropdownMenuItem<String>(
                            value: region['codigo'],
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${region['codigo']}: ${region['nombre']}',
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            regionSeleccionada = value;
                            ciudadSeleccionada = null;
                            lineaSeleccionada = null;
                            lineasDisponibles = [];
                            ciudadesFiltradas = _ciudades
                                .where((c) => c['codigo_region'] == value)
                                .toList();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Selector de Ciudad
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Ciudad',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        value: ciudadSeleccionada,
                        hint: const Text('Selecciona una ciudad'),
                        items: ciudadesFiltradas.map<DropdownMenuItem<String>>((
                          ciudad,
                        ) {
                          return DropdownMenuItem<String>(
                            value: ciudad['nombre'],
                            child: Text(
                              ciudad['nombre'],
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: regionSeleccionada == null
                            ? null
                            : (value) async {
                                setModalState(() {
                                  ciudadSeleccionada = value;
                                  lineaSeleccionada = null;
                                  cargandoLineas = true;
                                  lineasDisponibles = [];
                                });

                                if (value != null) {
                                  final lineas = await _cargarLineas(value);
                                  setModalState(() {
                                    lineasDisponibles = lineas;
                                    cargandoLineas = false;
                                  });
                                }
                              },
                      ),
                      const SizedBox(height: 16),

                      // Indicador de carga
                      if (cargandoLineas)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),

                      // Selector de Línea
                      if (!cargandoLineas && lineasDisponibles.isNotEmpty)
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Línea de colectivo',
                            prefixIcon: const Icon(Icons.directions_bus),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          value: lineaSeleccionada,
                          hint: const Text('Selecciona una línea'),
                          items: lineasDisponibles.map<DropdownMenuItem<String>>((
                            linea,
                          ) {
                            return DropdownMenuItem<String>(
                              value: linea['id'],
                              child: Text(
                                '${linea['nombre']} - ${linea['descripcion']}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() => lineaSeleccionada = value);
                          },
                        ),

                      // Sin líneas disponibles
                      if (!cargandoLineas &&
                          ciudadSeleccionada != null &&
                          lineasDisponibles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No hay líneas disponibles para $ciudadSeleccionada',
                                    style: TextStyle(
                                      color: Colors.orange[800],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Botón Buscar
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed:
                              lineaSeleccionada == null || _buscandoConductores
                              ? null
                              : () {
                                  Navigator.pop(context);
                                  _buscarConductores(
                                    linea: lineaSeleccionada!,
                                    region: regionSeleccionada,
                                    ciudad: ciudadSeleccionada,
                                  );
                                },
                          icon: _buscandoConductores
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.search, color: Colors.white),
                          label: Text(
                            _buscandoConductores
                                ? 'Buscando...'
                                : 'Buscar conductores',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            disabledBackgroundColor: Colors.blue[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botón Cancelar
                      SizedBox(
                        width: double.infinity,
                        height: 45,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _buscarConductores({
    required String linea,
    String? region,
    String? ciudad,
  }) async {
    if (_userPosition == null) {
      _mostrarMensaje('Primero debes activar tu ubicación GPS');
      return;
    }

    setState(() => _buscandoConductores = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) {
        throw Exception('No hay sesión activa');
      }

      final ciudadNormalizada = ciudad != null
          ? _normalizarCiudad(ciudad)
          : null;

      final queryParams = {
        'linea': linea,
        'radio_km': '7',
        'solo_activos': 'true',
        if (region != null && region.isNotEmpty) 'region': region,
        if (ciudadNormalizada != null && ciudadNormalizada.isNotEmpty)
          'ciudad': ciudadNormalizada,
      };

      final uri = Uri.parse(
        ApiConfig.geoConductoresCercanos,
      ).replace(queryParameters: queryParams);

      debugPrint('Buscando conductores con params: $queryParams');

      final response = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final conductores = data['conductores'] as List<dynamic>;

        setState(() => _buscandoConductores = false);
        _mostrarConductoresEnMapa(conductores);

        if (conductores.isEmpty) {
          _mostrarAlertaSinConductores(linea);
        } else {
          _mostrarMensaje('${conductores.length} conductor(es) encontrados');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Sesión expirada. Vuelve a iniciar sesión.');
      } else if (response.statusCode == 403) {
        throw Exception(
          'Necesitas una suscripción activa para buscar conductores.',
        );
      } else {
        throw Exception('Error del servidor: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _buscandoConductores = false);
      _mostrarMensaje('Error: ${e.toString()}');
    }
  }

  void _mostrarConductoresEnMapa(List<dynamic> conductores) {
    if (_userPosition == null) return;

    final Set<Marker> nuevosMarcadores = {};

    nuevosMarcadores.add(
      Marker(
        markerId: const MarkerId('yo'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Mi ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    for (var i = 0; i < conductores.length; i++) {
      final c = conductores[i];
      final lat = c['lat'] as double;
      final lng = c['lng'] as double;
      final linea = c['linea'] as String;
      final distancia = c['distancia_km'] as double;
      final tiempo = c['tiempo_llegada_estimado_min'] as double;

      nuevosMarcadores.add(
        Marker(
          markerId: MarkerId('conductor_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Línea $linea',
            snippet: '${distancia}km • ~${tiempo}min llegada',
          ),
          onTap: () => _mostrarDetalleConductor(c),
        ),
      );
    }

    setState(() => _markers = nuevosMarcadores);

    if (conductores.isNotEmpty && _mapController != null) {
      _ajustarCamaraAMarcadores();
    }
  }

  void _ajustarCamaraAMarcadores() {
    if (_markers.isEmpty || _mapController == null) return;

    final List<LatLng> posiciones = _markers.map((m) => m.position).toList();

    double minLat = posiciones.first.latitude;
    double maxLat = posiciones.first.latitude;
    double minLng = posiciones.first.longitude;
    double maxLng = posiciones.first.longitude;

    for (final pos in posiciones) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
  }

  void _mostrarAlertaSinConductores(String linea) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No hay conductores'),
        content: Text(
          'No encontramos conductores de la línea $linea cerca de ti en este momento.\n\n'
          'Intenta con otra línea o verifica más tarde.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarBuscadorConductores();
            },
            child: const Text('Buscar otra línea'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetalleConductor(dynamic conductor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Línea ${conductor['linea']}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${conductor['ciudad']}, ${conductor['region']}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _filaInformacion(
                  Icons.social_distance,
                  'Distancia',
                  '${conductor['distancia_km']} km',
                ),
                _filaInformacion(
                  Icons.timer,
                  'Tiempo estimado',
                  '~${conductor['tiempo_llegada_estimado_min']} min',
                ),
                _filaInformacion(
                  Icons.local_gas_station,
                  'Estado vehículo',
                  conductor['estado_vehiculo'],
                ),
                _filaInformacion(
                  Icons.update,
                  'Última actualización',
                  conductor['actualizado_recientemente']
                      ? 'Hace instantes'
                      : 'Hace ${conductor['segundos_desde_actualizacion']} segundos',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _mostrarMensaje('Solicitud enviada al conductor');
                    },
                    icon: const Icon(Icons.check_circle, color: Colors.white),
                    label: const Text(
                      'Solicitar colectivo',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _filaInformacion(IconData icono, String etiqueta, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icono, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(
            '$etiqueta: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ========== DATOS DE USUARIO ==========

  Future<Map<String, String>> _getNombreEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String nombre = prefs.getString('nombre') ?? '';
    String apellido = prefs.getString('apellido') ?? '';
    String email = prefs.getString('correo') ?? '';

    if (nombre.isEmpty || email.isEmpty) {
      final token = prefs.getString('access_token');
      if (token != null) {
        try {
          final url = Uri.parse(ApiConfig.usuarioMe);
          final resp = await http.get(
            url,
            headers: {
              "Authorization": "Bearer $token",
              "accept": "application/json",
            },
          );
          if (resp.statusCode == 200) {
            final user = jsonDecode(resp.body);
            nombre = (user['nombre'] ?? '').toString();
            apellido = (user['apellido'] ?? '').toString();
            email = (user['correo'] ?? '').toString();
            await prefs.setString('nombre', nombre);
            await prefs.setString('apellido', apellido);
            await prefs.setString('correo', email);
            _networkError = null;
          } else if (resp.statusCode == 401) {
            _networkError =
                "Sesión expirada. Por favor, vuelve a iniciar sesión.";
            _mostrarMensaje(_networkError!);
          } else {
            _networkError =
                "Error de red (${resp.statusCode}). Intenta más tarde.";
            _mostrarMensaje(_networkError!);
          }
        } catch (e) {
          _networkError =
              "No se pudo conectar al servidor. Comprueba tu conexión.";
          _mostrarMensaje(_networkError!);
        }
      } else {
        _networkError =
            "Sesión no encontrada. Por favor, inicia sesión de nuevo.";
        _mostrarMensaje(_networkError!);
      }
    }
    final String nombreCompleto =
        ((nombre.isNotEmpty ? nombre : 'Nombre') +
                (apellido.isNotEmpty ? ' $apellido' : ''))
            .trim();
    return {
      'nombre': nombreCompleto.isNotEmpty
          ? nombreCompleto
          : 'Nombre del pasajero',
      'email': email.isNotEmpty ? email : 'correo@ejemplo.com',
    };
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mapaWidget;
    if (_loadingLocation) {
      mapaWidget = const Center(child: CircularProgressIndicator());
    } else if (_locationError != null) {
      mapaWidget = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _locationError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _loadCurrentLocation,
                  icon: const Icon(Icons.refresh),
                  label: const Text("Intentar de nuevo"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings),
                  label: const Text("Ajustes"),
                  onPressed: () async {
                    await openAppSettings();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    } else if (_userPosition == null) {
      mapaWidget = const Center(
        child: Text("No se pudo obtener la ubicación."),
      );
    } else {
      mapaWidget = GoogleMap(
        onMapCreated: (controller) => _mapController = controller,
        initialCameraPosition: CameraPosition(
          target: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          zoom: 15,
        ),
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Pasajero')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _datosUsuarioFuture,
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del pasajero';
            final email = snapshot.data?['email'] ?? 'correo@ejemplo.com';
            final tieneError = _networkError != null;

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(
                    nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  accountEmail: Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  currentAccountPicture: const CircleAvatar(
                    backgroundImage: AssetImage('assets/avatar_default.png'),
                  ),
                  decoration: const BoxDecoration(color: Colors.blue),
                ),
                if (tieneError)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      _networkError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ListTile(
                  leading: const Icon(Icons.manage_accounts),
                  title: const Text('Mi Cuenta'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PerfilPasajeroScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.payment),
                  title: const Text('Pagar suscripción'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PagoSuscripcionScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Estado de suscripción'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EstadoSuscripcionPasajeroScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Historial de pagos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistorialPagoPasajeroScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y soporte'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AyudaSoporteScreen(),
                      ),
                    );
                  },
                ),
                const Divider(),
                const LogoutButton(),
              ],
            );
          },
        ),
      ),
      body: mapaWidget,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _buscandoConductores ? null : _mostrarBuscadorConductores,
        icon: _buscandoConductores
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.search, color: Colors.white, size: 28),
        label: Text(
          _buscandoConductores ? 'Buscando...' : 'Buscar colectivo',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: _buscandoConductores
            ? Colors.blue[600]
            : Colors.blue[800],
        disabledElevation: 0,
        elevation: 4,
      ),
    );
  }
}
