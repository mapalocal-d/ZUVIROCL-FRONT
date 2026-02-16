import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'ayuda_soporte.dart'; // Importa la pantalla de ayuda y soporte

class DashboardConductor extends StatefulWidget {
  const DashboardConductor({Key? key}) : super(key: key);

  @override
  State<DashboardConductor> createState() => _DashboardConductorState();
}

class _DashboardConductorState extends State<DashboardConductor> {
  late Future<Map<String, String>> _datosUsuarioFuture;
  Position? _userPosition;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _loadingLocation = true;

  @override
  void initState() {
    super.initState();
    _datosUsuarioFuture = _getNombreEmail();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      setState(() {
        _loadingLocation = false;
      });
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _userPosition = position;
      _loadingLocation = false;
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
  }

  Future<Map<String, String>> _getNombreEmail() async {
    final prefs = await SharedPreferences.getInstance();
    String nombre = prefs.getString('nombre') ?? '';
    String apellido = prefs.getString('apellido') ?? '';
    String email = prefs.getString('email') ?? '';

    if (nombre.isEmpty || email.isEmpty) {
      final token = prefs.getString('access_token');
      if (token != null) {
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
        }
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel Conductor')),
      drawer: Drawer(
        child: FutureBuilder<Map<String, String>>(
          future: _datosUsuarioFuture,
          builder: (context, snapshot) {
            final nombre = snapshot.data?['nombre'] ?? 'Nombre del conductor';
            final email = snapshot.data?['email'] ?? 'correo@ejemplo.com';

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
              ],
            );
          },
        ),
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : _userPosition == null
          ? const Center(child: Text("No se pudo obtener la ubicación."))
          : GoogleMap(
              onMapCreated: (controller) => _mapController = controller,
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  _userPosition!.latitude,
                  _userPosition!.longitude,
                ),
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
    );
  }
}
