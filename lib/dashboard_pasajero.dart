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
import 'package:permission_handler/permission_handler.dart'; // <-- Para abrir los ajustes

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
        // Mostrar snackbar
        _showSnackBar("Permiso de ubicación denegado.");
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _loadingLocation = false;
          _locationError =
              "Permiso de ubicación denegado permanentemente. Habilítalo desde Ajustes para ver el mapa.";
        });
        // Mostrar snackbar con opción para abrir ajustes
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
    final prefs = await SharedPreferences.getInstance();
    String nombre = prefs.getString('nombre') ?? '';
    String apellido = prefs.getString('apellido') ?? '';
    String email = prefs.getString('email') ?? '';

    if (nombre.isEmpty || email.isEmpty) {
      final token = prefs.getString('access_token');
      if (token != null) {
        try {
          final url = Uri.parse(
            'https://graceful-balance-production-ef1d.up.railway.app/users/me',
          );
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
            email = (user['email'] ?? '').toString();
            await prefs.setString('nombre', nombre);
            await prefs.setString('apellido', apellido);
            await prefs.setString('email', email);
            _networkError = null;
          } else if (resp.statusCode == 401) {
            _networkError =
                "Sesión expirada. Por favor, vuelve a iniciar sesión.";
            _showSnackBar(_networkError!);
          } else {
            _networkError =
                "Error de red (${resp.statusCode}). Intenta más tarde.";
            _showSnackBar(_networkError!);
          }
        } catch (e) {
          _networkError =
              "No se pudo conectar al servidor. Comprueba tu conexión.";
          _showSnackBar(_networkError!);
        }
      } else {
        _networkError =
            "Sesión no encontrada. Por favor, inicia sesión de nuevo.";
        _showSnackBar(_networkError!);
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

  void _showSnackBar(String message) {
    // Usa WidgetsBinding para asegurar que está montado
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
      appBar: AppBar(title: const Text('Panel Pasajero')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _datosUsuarioFuture,
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del pasajero';
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
      body: mapWidget,
    );
  }
}
