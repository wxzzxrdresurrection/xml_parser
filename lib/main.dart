import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xml_parser/services/db.dart';
import 'package:xml_parser/ui/theme/app_theme.dart';
import 'ui/pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final logDir = Directory(
    p.join(
      Platform.environment['LOCALAPPDATA'] ?? Directory.systemTemp.path,
      'XMLParser',
    ),
  );

  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }

  final logFile = File(p.join(logDir.path, 'flutter_log.txt'));

  void log(String msg) {
    logFile.writeAsStringSync(
      '${DateTime.now()} | $msg\n',
      mode: FileMode.append,
    );
  }

  FlutterError.onError = (details) {
    log('FLUTTER ERROR: ${details.exception}');
    log(details.stack.toString());
  };

  runZonedGuarded(
    () async {
      log('APP START');

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        log('INIT SQLITE FFI');
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      log('OPEN DATABASE');
      await DatabaseHelper.instance.database;

      log('RUN APP');
      runApp(const MyApp());
    },
    (error, stack) {
      log('FATAL ERROR: $error');
      log(stack.toString());
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // ignore: library_private_types_in_public_api
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();
}

class _MyAppState extends State<MyApp> {
  // Arranca siguiendo el tema del sistema operativo.
  ThemeMode _themeMode = ThemeMode.system;

  /// Cambia al tema opuesto del que se está mostrando actualmente.
  void toggleTheme(Brightness current) {
    setState(() {
      _themeMode = current == Brightness.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CFDI Reader',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
