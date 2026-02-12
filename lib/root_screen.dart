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
    if (token != null && token.isNotEmpty) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    } else {
      Navigator.of(
        context,
      ).pushReplacementNamed('/home'); // <--- EL CAMBIO AQUÍ
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
