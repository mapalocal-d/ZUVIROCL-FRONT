import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/storage_service.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      await _initializeApp();
    },
    (error, stack) {
      _logError('ZONE ERROR', error, stack);
    },
  );
}

Future<void> _initializeApp() async {
  // =========================================================
  // 1. INICIALIZAR FLUTTER
  // =========================================================
  WidgetsFlutterBinding.ensureInitialized();

  // =========================================================
  // 2. INICIALIZAR STORAGE CON RECUPERACIÓN DE ERRORES
  // =========================================================
  try {
    await StorageService().init();
  } catch (e, stack) {
    _logError('STORAGE INIT FAILED', e, stack);
    // App arranca sin sesión previa — no es crítico
  }

  // =========================================================
  // 3. ESCUDO DE ERRORES DE UI
  // =========================================================
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    _logError('FLUTTER ERROR', details.exception, details.stack);
  };

  // =========================================================
  // 4. ESCUDO DE ERRORES ASÍNCRONOS
  // =========================================================
  PlatformDispatcher.instance.onError = (error, stack) {
    _logError('ASYNC ERROR', error, stack);
    return true;
  };

  // =========================================================
  // 5. CONFIGURACIÓN VISUAL DEL SISTEMA
  // =========================================================
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // =========================================================
  // 6. BLOQUEAR ORIENTACIÓN
  // =========================================================
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (e, stack) {
    _logError('ORIENTATION ERROR', e, stack);
  }

  // =========================================================
  // 7. INICIAR APP
  // =========================================================
  runApp(const ZuviroApp());
}

void _logError(String type, Object error, StackTrace? stack) {
  final message = '''
╔══════════════════════════════════════════════════════════╗
║  ZUVIRO ERROR: $type
╠══════════════════════════════════════════════════════════╣
  Error: $error
  Stack: ${stack?.toString().split('\n').take(5).join('\n')}
╚══════════════════════════════════════════════════════════╝''';

  if (kDebugMode) {
    debugPrint(message);
  } else {
    developer.log(message, name: 'Zuviro', error: error, stackTrace: stack);
    // TODO: Integrar Sentry/Crashlytics aquí
  }
}
