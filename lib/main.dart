import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

// Importa tus pantallas
import 'dashboard_conductor.dart';
import 'dashboard_pasajero.dart';
import 'register_passenger.dart';
import 'register_driver.dart';
import 'login_screen.dart';
import 'reset_password_request_passenger.dart';
import 'reset_password_confirm_passenger.dart';
import 'reset_password_request_conductor.dart';
import 'reset_password_confirm_conductor.dart';
import 'root_screen.dart';

void main() {
  runApp(const ZuviroApp());
}

class ZuviroApp extends StatelessWidget {
  const ZuviroApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color background = Colors.black;
    const Color primary = Color(0xFF007AFF);
    const Color accent2 = Color(0xFF222B3A);
    const Color accent = Color(0xFF3CDFFF);
    const Color textColor = Color(0xFFE3F2FD);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ZUVIROCL',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        primaryColor: primary,
        colorScheme: ColorScheme.dark(
          primary: primary,
          background: background,
          surface: accent2,
          onPrimary: Colors.white,
          onSurface: Colors.white70,
          secondary: accent,
        ),
        appBarTheme: AppBarTheme(
          color: Colors.transparent,
          iconTheme: const IconThemeData(color: primary),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.dmSerifDisplay(
            color: textColor,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            fontSize: 28,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 4,
            minimumSize: const Size.fromHeight(54),
            textStyle: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.7,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent, width: 2),
            textStyle: GoogleFonts.montserrat(
              fontWeight: FontWeight.w600,
              fontSize: 17,
              letterSpacing: 0.5,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: accent2,
          labelStyle: TextStyle(color: accent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: accent, width: 2),
          ),
        ),
        cardColor: accent2,
      ),
      home: const RootScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/register-passenger': (_) => const RegisterPassengerScreen(),
        '/register-driver': (_) => const RegisterDriverScreen(),
        '/login': (_) => const LoginScreen(),
        '/dashboard_conductor': (_) => const DashboardConductor(),
        '/dashboard_pasajero': (_) => const DashboardPasajero(),
        '/reset-passenger-request': (_) =>
            const ResetPasswordRequestPassengerScreen(),
        '/reset-passenger-confirm': (_) =>
            const ResetPasswordConfirmPassengerScreen(),
        '/reset-conductor-request': (_) =>
            const ResetPasswordRequestConductorScreen(),
        '/reset-conductor-confirm': (_) =>
            const ResetPasswordConfirmConductorScreen(),
      },
    );
  }
}

// HomeScreen y botón de acceso rápido (puedes dejar igual que antes):
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showAccountOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            'Crear cuenta como',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3CDFFF),
            ),
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF007AFF),
            ),
            title: const Text('Pasajero'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register-passenger');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.directions_car_filled_outlined,
              color: Color(0xFF007AFF),
            ),
            title: const Text('Conductor'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register-driver');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showResetOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          Text(
            'Recuperar clave de',
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3CDFFF),
            ),
          ),
          const SizedBox(height: 6),
          ListTile(
            leading: const Icon(
              Icons.person_outline_rounded,
              color: Color(0xFF007AFF),
            ),
            title: const Text('Pasajero'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reset-passenger-request');
            },
          ),
          ListTile(
            leading: const Icon(
              Icons.directions_car_filled_outlined,
              color: Color(0xFF007AFF),
            ),
            title: const Text('Conductor'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reset-conductor-request');
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = Theme.of(context).colorScheme.secondary;
    final double svgHeight = 190;
    final double topSpace = MediaQuery.of(context).size.height < 700 ? 32 : 84;
    final double buttonMargin = 80;
    final double buttonTopOffset = topSpace + svgHeight + buttonMargin;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // SVG más grande
            Positioned(
              right: 0,
              left: 0,
              top: topSpace,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: SvgPicture.asset(
                    "assets/mapa_demo_actualizado.svg",
                    height: svgHeight,
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Botones más abajo
            Positioned(
              left: 0,
              right: 0,
              top: buttonTopOffset,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FancyButton(
                    text: 'Iniciar sesión',
                    icon: Icons.login,
                    color: Colors.white.withOpacity(0.10),
                    width: 230,
                    textColor: accent,
                    onPressed: () => Navigator.pushNamed(context, '/login'),
                  ),
                  const SizedBox(height: 18),
                  _FancyButton(
                    text: 'Crear cuenta',
                    icon: Icons.person_add_alt_rounded,
                    color: Colors.white.withOpacity(0.10),
                    width: 230,
                    textColor: accent,
                    onPressed: () => _showAccountOptions(context),
                  ),
                  const SizedBox(height: 18),
                  _FancyButton(
                    text: 'Recuperar contraseña',
                    icon: Icons.lock_reset_rounded,
                    color: const Color(0xFF1DE9B6).withOpacity(0.11),
                    width: 230,
                    textColor: const Color(0xFF1DE9B6),
                    onPressed: () => _showResetOptions(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FancyButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final double width;
  final Color? textColor;
  const _FancyButton({
    required this.text,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.width = 230,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22);
    final labelColor = textColor ?? color;

    return Center(
      child: SizedBox(
        width: width,
        height: 50,
        child: OutlinedButton.icon(
          icon: Icon(icon, color: labelColor, size: 22),
          label: Text(
            text,
            style: GoogleFonts.montserrat(
              color: labelColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: 0.4,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(width: 1.5, color: labelColor.withOpacity(0.24)),
            backgroundColor: color,
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}
