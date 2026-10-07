import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/home.dart';
import 'services/db.dart';
import 'state/app_state.dart';
import 'state/app_state_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  final db = Db();
  await db.init();

  final state = AppState(db);
  unawaited(state.bootstrap());

  runApp(MiniTiktokApp(state: state));
}

class MiniTiktokApp extends StatelessWidget {
  const MiniTiktokApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: state,
      child: MaterialApp(
        title: 'Mini TikTok',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFF111114),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF2D78),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF111114),
            elevation: 0,
          ),
        ),
        home: const Home(),
      ),
    );
  }
}
