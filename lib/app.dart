import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

class ZuviroApp extends StatelessWidget {
  const ZuviroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. Llave global de navegación (usada por AppNavigator.forceLogout)
      navigatorKey: AppNavigator.navigatorKey,

      debugShowCheckedModeBanner: false,
      title: 'ZUVIRO',

      // 2. Localización es_CL (requerido para intl: fechas, moneda)
      locale: const Locale('es', 'CL'),
      supportedLocales: const [Locale('es', 'CL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 3. Tema Negro + Esmeralda
      theme: AppTheme.darkTheme,

      // 4. Rutas
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,

      // 5. Restauración de estado (deep links, app killed)
      restorationScopeId: 'zuviro_app',

      // 6. Builder global: evita que el texto se deforme con
      //    la configuración de accesibilidad del sistema
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}
