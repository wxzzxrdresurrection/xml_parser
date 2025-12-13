import 'dart:io';
import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:xml_parser/services/db.dart';
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

  runZonedGuarded(() async {
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
  }, (error, stack) {
    log('FATAL ERROR: $error');
    log(stack.toString());
  });
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
  ThemeMode _themeMode = ThemeMode.light;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CFDI Reader',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}