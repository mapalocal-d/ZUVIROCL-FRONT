import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logout_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _token;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('access_token');
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [LogoutButton()],
      ),
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Card(
            color: theme.colorScheme.surface,
            elevation: 7,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.dashboard_rounded,
                    size: 72,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '¡Bienvenido a ZUVIROCL!',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 26,
                      color: theme.colorScheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Este es tu panel principal.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 26),
                  _loading
                      ? const CircularProgressIndicator()
                      : _token == null
                      ? const Text(
                          "No autenticado. Por favor inicia sesión.",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        )
                      : _JwtCard(token: _token!),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _JwtCard extends StatelessWidget {
  final String token;
  const _JwtCard({required this.token});

  @override
  Widget build(BuildContext context) {
    final preview = token.length > 24
        ? '${token.substring(0, 12)}...${token.substring(token.length - 12)}'
        : token;
    return Column(
      children: [
        Text("Token de acceso:", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 7),
        SelectableText(
          preview,
          style: const TextStyle(
            fontSize: 15,
            backgroundColor: Colors.transparent,
            color: Color(0xFF3CDFFF),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.3,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
