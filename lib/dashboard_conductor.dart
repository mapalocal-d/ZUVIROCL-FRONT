import 'package:flutter/material.dart';
import 'perfil_conductor.dart';
import 'pago_suscripcion_conductor.dart';
import 'estado_suscripcion_conductor.dart';
import 'historial_pago_conductor.dart';
import 'ayuda_soporte.dart';
import 'logout_button.dart';
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

class _DashboardConductorState extends State<DashboardConductor> {
  final _api = ApiClient();
  final _secure = SecureStorage();
  late Future<Map<String, String>> _datosUsuarioFuture;
  Position? _userPosition;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _loadingLocation = true;
  String? _locationError;
  String? _networkError;

  @override
  void initState() {
    super.initState();
    _datosUsuarioFuture = _getNombreEmail();
    _loadCurrentLocation();
  }

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

  Future<Map<String, String>> _getNombreEmail() async {
    // 1. Cargar datos locales inmediatamente (caché)
    String nombre = await _secure.getNombre() ?? '';
    String apellido = await _secure.getApellido() ?? '';
    String email = await _secure.getCorreo() ?? '';

    // 2. Siempre actualizar desde el servidor en background
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
    _mapController?.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Panel Conductor')),
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
                        builder: (_) =>
                            const EstadoSuscripcionConductorScreen(),
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
                const Divider(),
                const LogoutButton(),
              ],
            );
          },
        ),
      ),
      body: mapWidget,
    );
  }
}
