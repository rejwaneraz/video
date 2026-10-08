import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import 'screens/app_shell.dart';
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
        title: 'Videos',
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
        home: const LockGate(child: AppShell()),
      ),
    );
  }
}

/// Fingerprint gate shown on app open. If the device has no biometrics
/// enrolled/supported it passes straight through.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> {
  bool _unlocked = false;
  bool _checking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _auth();
  }

  Future<void> _auth() async {
    setState(() {
      _checking = true;
      _error = null;
    });
    final la = LocalAuthentication();
    try {
      final enrolled = await la.canCheckBiometrics;
      final supported = await la.isDeviceSupported();
      if (!enrolled || !supported) {
        if (mounted) {
          setState(() {
            _unlocked = true;
            _checking = false;
          });
        }
        return;
      }
      final ok = await la.authenticate(
        localizedReason: 'App khulte fingerprint verify korun',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      setState(() {
        _unlocked = ok;
        _checking = false;
        _error = ok ? null : 'Fingerprint match hoy ni. Abar chesta korun.';
      });
    } catch (_) {
      // No biometric hardware / not enrolled / cancelled policy -> allow.
      if (mounted) {
        setState(() {
          _unlocked = true;
          _checking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return widget.child;
    return Scaffold(
      backgroundColor: const Color(0xFF111114),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fingerprint, size: 84, color: Color(0xFFFF2D78)),
            const SizedBox(height: 18),
            const Text(
              'Videos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            if (_checking)
              const CircularProgressIndicator(color: Color(0xFFFF2D78))
            else
              ElevatedButton.icon(
                onPressed: _auth,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D78),
                  foregroundColor: Colors.white,
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
