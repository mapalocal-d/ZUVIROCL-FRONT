import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../theme/app_theme.dart';

/// Centralizamos los nombres de las rutas para evitar errores de tipeo.
class AppRoutes {
  static const String splash = '/';
  static const String selectRole = '/select-role';
  static const String login = '/login';
  static const String registerPasajero = '/register/pasajero';
  static const String registerConductor = '/register/conductor';
  static const String recuperarContrasena = '/recuperar';
  static const String dashboardPasajero = '/dashboard/pasajero';
  static const String dashboardConductor = '/dashboard/conductor';
  static const String suscripcionCrear = '/suscripcion/crear';
  static const String suscripcionHistorial = '/suscripcion/historial';
  static const String perfilPasajero = '/perfil/pasajero';
  static const String perfilConductor = '/perfil/conductor';
  static const String cambiarContrasena = '/perfil/cambiar-contrasena';
  static const String sesionesActivas = '/perfil/sesiones';
}

/// Generador de rutas que conecta pantallas a medida que se crean.
class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return _buildRoute(const SplashScreen(), settings);

      case AppRoutes.selectRole:
        return _buildRoute(
            const _PlaceholderScreen('Seleccionar Rol'), settings);

      case AppRoutes.login:
        return _buildRoute(const LoginScreen(), settings); // ← CONECTADO

      case AppRoutes.registerPasajero:
        return _buildRoute(
            const _PlaceholderScreen('Registro Pasajero'), settings);

      case AppRoutes.registerConductor:
        return _buildRoute(
            const _PlaceholderScreen('Registro Conductor'), settings);

      case AppRoutes.recuperarContrasena:
        return _buildRoute(
            const _PlaceholderScreen('Recuperar Contraseña'), settings);

      case AppRoutes.dashboardPasajero:
        return _buildRoute(const _PlaceholderScreen('Mapa Pasajero'), settings);

      case AppRoutes.dashboardConductor:
        return _buildRoute(
            const _PlaceholderScreen('Mapa Conductor'), settings);

      case AppRoutes.suscripcionCrear:
        return _buildRoute(
            const _PlaceholderScreen('Crear Suscripción'), settings);

      case AppRoutes.suscripcionHistorial:
        return _buildRoute(
            const _PlaceholderScreen('Historial de Pagos'), settings);

      case AppRoutes.perfilPasajero:
        return _buildRoute(
            const _PlaceholderScreen('Perfil Pasajero'), settings);

      case AppRoutes.perfilConductor:
        return _buildRoute(
            const _PlaceholderScreen('Perfil Conductor'), settings);

      case AppRoutes.cambiarContrasena:
        return _buildRoute(
            const _PlaceholderScreen('Cambiar Contraseña'), settings);

      case AppRoutes.sesionesActivas:
        return _buildRoute(
            const _PlaceholderScreen('Sesiones Activas'), settings);

      default:
        return _buildRoute(
            _ErrorScreen(routeName: settings.name ?? '??'), settings);
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}

// =============================================================
// HELPERS DE NAVEGACIÓN (AppNavigator)
// =============================================================

class AppNavigator {
  /// Llave global necesaria para redirigir desde el Interceptor de red.
  static final navigatorKey = GlobalKey<NavigatorState>();

  static void toDashboard(BuildContext context, String rol) {
    final route = rol == 'conductor'
        ? AppRoutes.dashboardConductor
        : AppRoutes.dashboardPasajero;
    Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
  }

  static void toLogin(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  static void forceLogout() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.login,
      (_) => false,
    );
  }

  static void to(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushNamed(context, route, arguments: arguments);
  }

  static void replace(BuildContext context, String route, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, route, arguments: arguments);
  }

  static void back(BuildContext context) {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }
}

// =============================================================
// VISTAS DE TRANSICIÓN (Placeholders con AppTheme)
// =============================================================

class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title.toUpperCase(),
            style: const TextStyle(fontSize: 16, letterSpacing: 1.2)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(
              'CONSTRUYENDO:\n$title',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textMuted,
                letterSpacing: 2,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorScreen extends StatelessWidget {
  final String routeName;
  const _ErrorScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppTheme.error, size: 80),
              const SizedBox(height: 24),
              const Text(
                'RUTA NO ENCONTRADA',
                style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              Text('"$routeName"',
                  style: const TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 40),
              ElevatedButton(
                style:
                    ElevatedButton.styleFrom(backgroundColor: AppTheme.surface),
                onPressed: () => AppNavigator.toLogin(context),
                child: const Text('VOLVER AL INICIO',
                    style: TextStyle(color: AppTheme.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
