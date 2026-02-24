import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // Importante para el idioma

import 'theme/app_theme.dart';
import 'routes/app_routes.dart';

class ZuviroApp extends StatelessWidget {
  const ZuviroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 1. Llave global de navegación desde AppNavigator (evita import circular a main.dart)
      navigatorKey: AppNavigator.navigatorKey,

      debugShowCheckedModeBanner: false,
      title: 'ZUVIRO',

      // 2. Localización para formato de fechas y moneda (intl)
      // Se agregan delegados para que los widgets del sistema también hablen español
      locale: const Locale('es', 'CL'),
      supportedLocales: const [Locale('es', 'CL')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 3. Tema Dark Premium Esmeralda
      theme: AppTheme.darkTheme,

      // 4. Sistema de rutas
      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,

      // 5. Builder global: controla el escalado de texto
      // Evita que las configuraciones de accesibilidad del teléfono rompan el diseño
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        );
      },
    );
  }
}
