import 'package:flutter/material.dart';
import 'perfil_conductor.dart';
import 'pago_suscripcion_conductor.dart';
import 'estado_suscripcion_conductor.dart';
import 'historial_pago_conductor.dart';
import 'ayuda_soporte.dart';
import 'logout_button.dart';
import 'sesiones_activas.dart';
import 'dart:async';
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'secure_storage.dart';
import 'app_logger.dart';

class DashboardConductor extends StatefulWidget {
  const DashboardConductor({Key? key}) : super(key: key);

  @override
  State<DashboardConductor> createState() => _DashboardConductorState();
}

class _DashboardConductorState extends State<DashboardConductor>
    with WidgetsBindingObserver {
  final _api = ApiClient();
  final _secure = SecureStorage();
  late Future<Map<String, String>> _datosUsuarioFuture;
  Position? _userPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _loadingLocation = true;
  String? _locationError;
  String? _networkError;

  // ========== ESTADO DE TRABAJO ==========
  bool _trabajando = false;
  bool _toggleTrabajoCargando = false;
  Timer? _gpsTimer;
  static const int _gpsIntervalSeconds = 6;

  // ========== ESTADO VEHÍCULO ==========
  String _estadoVehiculo = 'disponible';
  bool _estadoVehiculoCargando = false;

  // ========== PASAJEROS CERCANOS ==========
  List<dynamic> _pasajerosCercanos = [];

  // ========== SUSCRIPCIÓN ==========
  bool _suscripcionActiva = true;
  bool _suscripcionCargando = true;
  String _suscripcionEstado = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _datosUsuarioFuture = _getNombreEmail();
    _loadCurrentLocation();
    _cargarEstadoInicial();
    _verificarSuscripcion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused && _trabajando) {
      AppLogger.i('App en background. GPS sigue activo.');
    }
    if (state == AppLifecycleState.resumed && _trabajando) {
      AppLogger.i('App en foreground. Actualizando ubicación.');
      _enviarUbicacion();
    }
    if (state == AppLifecycleState.resumed) {
      _verificarSuscripcion();
    }
  }

  // ========== VERIFICAR SUSCRIPCIÓN CONDUCTOR (OPTIMIZADO) ==========

  Future<void> _verificarSuscripcion() async {
    // 1. Evitar múltiples llamadas simultáneas o llamadas cuando el widget ya no existe
    if (!mounted || _suscripcionCargando) return;

    setState(() => _suscripcionCargando = true);

    try {
      final resp = await _api.get(ApiConfig.suscripcionEstado);

      // 2. Comprobar si el usuario sigue en esta pantalla tras la respuesta del servidor
      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final bool tieneSuscripcion = data['tiene_suscripcion'] == true;
        final bool estaActivo = data['esta_activo'] == true;
        final String estado = data['estado']?.toString() ?? '';

        setState(() {
          _suscripcionActiva = tieneSuscripcion && estaActivo;
          _suscripcionEstado = estado;
          _suscripcionCargando = false;
        });

        AppLogger.i(
          'Suscripción conductor: activa=$_suscripcionActiva, estado=$estado',
        );

        // 3. Lógica Crítica: Si la suscripción no está activa pero el conductor figura como "Trabajando"
        if (!_suscripcionActiva && _trabajando) {
          // Detenemos el Timer del GPS inmediatamente
          _detenerEnvioGPS();

          setState(() {
            _trabajando = false;
            _pasajerosCercanos = [];
            // Limpiamos el mapa: dejamos solo el marcador del conductor ('me')
            _markers = _markers.where((m) => m.markerId.value == 'me').toSet();
            // Opcional: Volver a estado 'disponible' o 'fuera de servicio' en el backend
            _estadoVehiculo = 'disponible';
          });

          _showSnackBar(
            '⚠️ Suscripción vencida o inactiva. El modo trabajo se ha desactivado.',
          );
        }
      } else {
        // Si el servidor responde un error (401, 404, 500), por seguridad asumimos inactiva
        setState(() {
          _suscripcionActiva = false;
          _suscripcionCargando = false;
        });
      }
    } on SinConexionException {
      if (mounted) {
        setState(() => _suscripcionCargando = false);
        AppLogger.w('Sin conexión al verificar suscripción conductor.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _suscripcionCargando = false);
        AppLogger.e('Error crítico verificando suscripción conductor', e);
      }
    }
  }
  // ========== OVERLAY DE SUSCRIPCIÓN ==========

  Widget _buildOverlaySuscripcion() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 80, color: Colors.red[400]),
              const SizedBox(height: 20),
              const Text(
                'Suscripción requerida',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                _suscripcionEstado == 'expired'
                    ? 'Tu suscripción ha vencido.\nRenueva para volver a trabajar.'
                    : 'No tienes una suscripción activa.\nPaga para comenzar a trabajar.',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PagoSuscripcionConductorScreen(),
                      ),
                    ).then((_) => _verificarSuscripcion());
                  },
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text(
                    'Pagar suscripción',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_suscripcionEstado == 'expired') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const EstadoSuscripcionConductorScreen(),
                        ),
                      ).then((_) => _verificarSuscripcion());
                    },
                    icon: const Icon(Icons.autorenew, color: Colors.white),
                    label: const Text(
                      'Renovar suscripción',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: _verificarSuscripcion,
                child: const Text(
                  'Ya pagué, verificar de nuevo',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== ESTADO INICIAL ==========

  Future<void> _cargarEstadoInicial() async {
    try {
      final resp = await _api.get(ApiConfig.geoEstadoVehiculo);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        setState(() {
          _estadoVehiculo = data['estado_vehiculo'] ?? 'disponible';
        });
        AppLogger.i('Estado vehículo cargado: $_estadoVehiculo');
      }
    } catch (e) {
      AppLogger.w('No se pudo cargar estado inicial del vehículo.');
    }
  }

  // ========== GPS: ENVIAR UBICACIÓN (#4) ==========

  void _iniciarEnvioGPS() {
    _gpsTimer?.cancel();
    _enviarUbicacion();
    _gpsTimer = Timer.periodic(
      const Duration(seconds: _gpsIntervalSeconds),
      (_) => _enviarUbicacion(),
    );
    AppLogger.i('GPS activado: enviando cada ${_gpsIntervalSeconds}s');
  }

  void _detenerEnvioGPS() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    AppLogger.i('GPS desactivado.');
  }

  Future<void> _enviarUbicacion() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _userPosition = position;
        _markers = {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
          ..._markers.where((m) => m.markerId.value != 'me'),
        };
      });

      final resp = await _api.patch(
        ApiConfig.geoActualizar,
        body: {"lat": position.latitude, "lng": position.longitude},
      );

      if (resp.statusCode == 200) {
        AppLogger.d(
          '📍 GPS enviado: ${position.latitude}, ${position.longitude}',
        );
      } else if (resp.statusCode == 403) {
        // Suscripción venció mientras trabajaba
        _detenerEnvioGPS();
        setState(() => _trabajando = false);
        _verificarSuscripcion();
        _showSnackBar('⚠️ Tu suscripción venció. Renueva para continuar.');
      } else {
        AppLogger.w('Error enviando GPS: ${resp.statusCode}');
      }
    } catch (e) {
      AppLogger.e('Error obteniendo/enviando ubicación', e);
    }
  }

  // ========== ESTADO DE TRABAJO (#11) ==========

  Future<void> _toggleEstadoTrabajo() async {
    // Verificar suscripción antes de activar trabajo
    if (!_trabajando && !_suscripcionActiva) {
      _showSnackBar('❌ Necesitas una suscripción activa para trabajar.');
      return;
    }

    setState(() => _toggleTrabajoCargando = true);

    final nuevoEstado = !_trabajando;

    try {
      final resp = await _api.patch(
        ApiConfig.geoEstadoTrabajo,
        body: {"activo": nuevoEstado},
      );

      if (resp.statusCode == 200) {
        setState(() {
          _trabajando = nuevoEstado;
        });

        if (_trabajando) {
          _iniciarEnvioGPS();
          _showSnackBar('✅ Estás trabajando. Los pasajeros pueden verte.');
        } else {
          _detenerEnvioGPS();
          setState(() {
            _pasajerosCercanos = [];
            _markers = _markers.where((m) => m.markerId.value == 'me').toSet();
          });
          _showSnackBar('⏸️ Dejaste de trabajar. Ya no eres visible.');
        }
        AppLogger.i('Estado trabajo: ${_trabajando ? "ACTIVO" : "INACTIVO"}');
      } else if (resp.statusCode == 403) {
        _verificarSuscripcion();
        _showSnackBar('❌ Tu suscripción no está activa.');
      } else {
        final body = jsonDecode(resp.body);
        final detail = body['detail'] ?? 'Error al cambiar estado de trabajo.';
        _showSnackBar('❌ $detail');
        AppLogger.w('Error toggle trabajo: ${resp.statusCode} - $detail');
      }
    } on SinConexionException {
      _showSnackBar('❌ Sin conexión a internet.');
    } catch (e) {
      AppLogger.e('Error en toggle estado trabajo', e);
      _showSnackBar('❌ Error al cambiar estado de trabajo.');
    } finally {
      setState(() => _toggleTrabajoCargando = false);
    }
  }

  // ========== ESTADO VEHÍCULO (#10) ==========

  Future<void> _cambiarEstadoVehiculo(String nuevoEstado) async {
    if (_estadoVehiculo == nuevoEstado) return;

    setState(() => _estadoVehiculoCargando = true);

    try {
      final resp = await _api.patch(
        ApiConfig.geoEstadoVehiculo,
        body: {"estado_vehiculo": nuevoEstado},
      );

      if (resp.statusCode == 200) {
        setState(() => _estadoVehiculo = nuevoEstado);
        AppLogger.i('Estado vehículo cambiado a: $nuevoEstado');

        final labels = {
          'disponible': '🟢 Con espacio',
          'lleno': '🔴 Lleno',
          'fuera_de_servicio': '⚫ Fuera de servicio',
        };
        _showSnackBar('Vehículo: ${labels[nuevoEstado] ?? nuevoEstado}');
      } else {
        _showSnackBar('❌ No se pudo cambiar el estado del vehículo.');
      }
    } on SinConexionException {
      _showSnackBar('❌ Sin conexión a internet.');
    } catch (e) {
      AppLogger.e('Error cambiando estado vehículo', e);
      _showSnackBar('❌ Error al cambiar estado del vehículo.');
    } finally {
      setState(() => _estadoVehiculoCargando = false);
    }
  }

  void _mostrarSelectorEstadoVehiculo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Estado del vehículo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _opcionEstadoVehiculo(
                'disponible',
                'Con espacio',
                Icons.check_circle,
                Colors.green,
              ),
              _opcionEstadoVehiculo('lleno', 'Lleno', Icons.cancel, Colors.red),
              _opcionEstadoVehiculo(
                'fuera_de_servicio',
                'Fuera de servicio',
                Icons.build,
                Colors.grey,
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _opcionEstadoVehiculo(
    String valor,
    String label,
    IconData icono,
    Color color,
  ) {
    final seleccionado = _estadoVehiculo == valor;
    return ListTile(
      leading: Icon(icono, color: color, size: 28),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
          color: seleccionado ? color : Colors.black87,
        ),
      ),
      trailing: seleccionado ? Icon(Icons.check, color: color) : null,
      onTap: () {
        Navigator.pop(context);
        _cambiarEstadoVehiculo(valor);
      },
    );
  }

  // ========== PASAJEROS CERCANOS (#5) ==========

  Future<void> _buscarPasajerosCercanos() async {
    if (_userPosition == null) return;

    try {
      final resp = await _api.get(ApiConfig.geoPasajerosCercanos);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final pasajeros = data['pasajeros'] as List<dynamic>? ?? [];

        setState(() => _pasajerosCercanos = pasajeros);
        _mostrarPasajerosEnMapa(pasajeros);

        if (pasajeros.isEmpty) {
          _showSnackBar('No hay pasajeros buscando tu línea cerca.');
        } else {
          _showSnackBar('${pasajeros.length} pasajero(s) cerca.');
        }
        AppLogger.i('Pasajeros cercanos: ${pasajeros.length}');
      }
    } catch (e) {
      AppLogger.e('Error buscando pasajeros cercanos', e);
    }
  }

  void _mostrarPasajerosEnMapa(List<dynamic> pasajeros) {
    if (_userPosition == null) return;

    final Set<Marker> nuevosMarcadores = {};

    nuevosMarcadores.add(
      Marker(
        markerId: const MarkerId('me'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        infoWindow: const InfoWindow(title: 'Mi ubicación'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    for (var i = 0; i < pasajeros.length; i++) {
      final p = pasajeros[i];
      final lat = (p['lat'] as num).toDouble();
      final lng = (p['lng'] as num).toDouble();

      nuevosMarcadores.add(
        Marker(
          markerId: MarkerId('pasajero_$i'),
          position: LatLng(lat, lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Pasajero buscando',
            snippet: p['linea'] ?? '',
          ),
        ),
      );
    }

    setState(() => _markers = nuevosMarcadores);
  }

  // ========== UBICACIÓN INICIAL ==========

  Future<void> _loadCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              "Permiso de ubicación denegado. Por favor, permite el acceso desde Ajustes.";
        });
        _showSnackBar("Permiso de ubicación denegado.");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              "Permiso de ubicación denegado permanentemente. Habilítalo desde Ajustes para ver el mapa.";
        });
        _showSnackBar("Debes habilitar el permiso de ubicación desde Ajustes.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _userPosition = position;
        _loadingLocation = false;
        _locationError = null;
        _markers = {
          Marker(
            markerId: const MarkerId('me'),
            position: LatLng(position.latitude, position.longitude),
            infoWindow: const InfoWindow(title: 'Mi ubicación'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        };
      });
    } catch (e) {
      setState(() {
        _loadingLocation = false;
        _locationError = "No se pudo obtener la ubicación. Intenta de nuevo.";
      });
      _showSnackBar("No se pudo obtener la ubicación.");
    }
  }

  // ========== DATOS DE USUARIO ==========

  Future<Map<String, String>> _getNombreEmail() async {
    String nombre = await _secure.getNombre() ?? '';
    String apellido = await _secure.getApellido() ?? '';
    String email = await _secure.getCorreo() ?? '';

    try {
      final resp = await _api.get(ApiConfig.usuarioMe);
      if (resp.statusCode == 200) {
        final user = jsonDecode(resp.body);
        nombre = (user['nombre'] ?? '').toString();
        apellido = (user['apellido'] ?? '').toString();
        email = (user['correo'] ?? '').toString();
        await _secure.guardarDatosUsuario(user);
        _networkError = null;
        AppLogger.i('Datos del conductor actualizados desde servidor.');
      } else {
        _networkError = "Error de red (${resp.statusCode}). Intenta más tarde.";
        AppLogger.w('Error obteniendo datos del conductor: ${resp.statusCode}');
        if (nombre.isEmpty) _showSnackBar(_networkError!);
      }
    } on SinConexionException {
      _networkError = "Sin conexión. Mostrando datos guardados.";
      AppLogger.w('Sin conexión en dashboard conductor.');
      if (nombre.isEmpty) _showSnackBar(_networkError!);
    } catch (e) {
      _networkError = "No se pudo conectar al servidor. Comprueba tu conexión.";
      AppLogger.e('Error en _getNombreEmail conductor', e);
      if (nombre.isEmpty) _showSnackBar(_networkError!);
    }

    final String nombreCompleto =
        ((nombre.isNotEmpty ? nombre : 'Nombre') +
                (apellido.isNotEmpty ? ' $apellido' : ''))
            .trim();
    return {
      'nombre': nombreCompleto.isNotEmpty
          ? nombreCompleto
          : 'Nombre del conductor',
      'email': email.isNotEmpty ? email : 'correo@ejemplo.com',
    };
  }

  void _showSnackBar(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detenerEnvioGPS();
    _mapController?.dispose();
    super.dispose();
  }

  // ========== UI ==========

  Color get _colorEstadoVehiculo {
    switch (_estadoVehiculo) {
      case 'disponible':
        return Colors.green;
      case 'lleno':
        return Colors.red;
      case 'fuera_de_servicio':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String get _labelEstadoVehiculo {
    switch (_estadoVehiculo) {
      case 'disponible':
        return 'Con espacio';
      case 'lleno':
        return 'Lleno';
      case 'fuera_de_servicio':
        return 'Fuera de servicio';
      default:
        return _estadoVehiculo;
    }
  }

  IconData get _iconEstadoVehiculo {
    switch (_estadoVehiculo) {
      case 'disponible':
        return Icons.check_circle;
      case 'lleno':
        return Icons.cancel;
      case 'fuera_de_servicio':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget mapWidget;
    if (_loadingLocation) {
      mapWidget = const Center(child: CircularProgressIndicator());
    } else if (_locationError != null) {
      mapWidget = Center(
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
      mapWidget = const Center(child: Text("No se pudo obtener la ubicación."));
    } else {
      mapWidget = GoogleMap(
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
      appBar: AppBar(
        title: const Text('Panel Conductor'),
        actions: [
          if (_trabajando)
            IconButton(
              onPressed: _estadoVehiculoCargando
                  ? null
                  : _mostrarSelectorEstadoVehiculo,
              icon: _estadoVehiculoCargando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(_iconEstadoVehiculo, color: _colorEstadoVehiculo),
              tooltip: 'Estado: $_labelEstadoVehiculo',
            ),
          if (_trabajando)
            IconButton(
              onPressed: _buscarPasajerosCercanos,
              icon: const Icon(Icons.people),
              tooltip: 'Ver pasajeros cercanos',
            ),
        ],
      ),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _datosUsuarioFuture,
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del conductor';
            final email = snapshot.data?['email'] ?? 'correo@ejemplo.com';
            final hasError = _networkError != null;

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
                if (hasError)
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
                        builder: (_) => const PerfilConductorScreen(),
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
                        builder: (_) => const PagoSuscripcionConductorScreen(),
                      ),
                    ).then((_) => _verificarSuscripcion());
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
                        builder: (_) =>
                            const EstadoSuscripcionConductorScreen(),
                      ),
                    ).then((_) => _verificarSuscripcion());
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
                        builder: (_) => const HistorialPagoConductorScreen(),
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
                ListTile(
                  leading: const Icon(Icons.devices),
                  title: const Text('Sesiones activas'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SesionesActivasScreen(),
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
      body: Stack(
        children: [
          mapWidget,
          // Barra de estado trabajando
          if (_trabajando)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _colorEstadoVehiculo.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      Icon(_iconEstadoVehiculo, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '🟢 Trabajando • $_labelEstadoVehiculo',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      if (_pasajerosCercanos.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pasajerosCercanos.length} 👤',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          // OVERLAY DE SUSCRIPCIÓN
          if (!_suscripcionCargando && !_suscripcionActiva)
            _buildOverlaySuscripcion(),
          // Loading de suscripción
          if (_suscripcionCargando)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Verificando suscripción...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!_suscripcionCargando && !_suscripcionActiva)
          ? null
          : FloatingActionButton.extended(
              onPressed: _toggleTrabajoCargando ? null : _toggleEstadoTrabajo,
              icon: _toggleTrabajoCargando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _trabajando ? Icons.stop : Icons.play_arrow,
                      color: Colors.white,
                      size: 28,
                    ),
              label: Text(
                _toggleTrabajoCargando
                    ? 'Cargando...'
                    : _trabajando
                    ? 'Dejar de trabajar'
                    : 'Empezar a trabajar',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              backgroundColor: _toggleTrabajoCargando
                  ? Colors.grey
                  : _trabajando
                  ? Colors.red[700]
                  : Colors.green[700],
              elevation: 4,
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
