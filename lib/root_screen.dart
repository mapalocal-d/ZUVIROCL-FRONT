import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});
  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    _checkIfLoggedIn();
  }

  Future<void> _checkIfLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final rol = prefs.getString('rol'); // <-- Lee el rol guardado
    if (token != null && token.isNotEmpty && rol != null && rol.isNotEmpty) {
      // Si el usuario tiene sesión y rol, navega según el rol:
      if (rol == "conductor") {
        Navigator.of(context).pushReplacementNamed('/dashboard_conductor');
      } else {
        Navigator.of(context).pushReplacementNamed('/dashboard_pasajero');
      }
    } else {
      // Si NO hay sesión, va a Home (landing/login)
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
