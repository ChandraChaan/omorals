import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase_options.dart';
import 'screens/auth.dart';
import 'screens/shell.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (const bool.fromEnvironment('USE_EMULATOR')) {
    await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
    FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  }
  await _preloadFonts();
  runApp(const OMoralsApp());
}

/// Fetches the two typefaces before the first frame so text doesn't reflow
/// when they arrive. Gives up quietly on a slow or missing connection.
Future<void> _preloadFonts() async {
  for (final weight in const [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w800,
  ]) {
    GoogleFonts.manrope(fontWeight: weight);
  }
  GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w700);
  try {
    await GoogleFonts.pendingFonts().timeout(const Duration(seconds: 3));
  } catch (_) {
    // The app still works with the fallback font; fonts load when they can.
  }
}

class OMoralsApp extends StatefulWidget {
  const OMoralsApp({super.key});

  @override
  State<OMoralsApp> createState() => _OMoralsAppState();
}

class _OMoralsAppState extends State<OMoralsApp> {
  final _store = AppStore();

  @override
  void dispose() {
    _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: _store,
      child: MaterialApp(
        title: 'OMorals Workspace',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        scaffoldMessengerKey: messengerKey,
        home: const _Root(),
      ),
    );
  }
}

/// Picks the top-level screen for the current auth / approval state.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  Phase? _last;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phase = StoreScope.of(context).phase;
    if (_last == Phase.active && phase != Phase.active) {
      // Close any dialogs left open over the workspace.
      final navigator = Navigator.of(context);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) navigator.popUntil((route) => route.isFirst);
      });
    }
    _last = phase;
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(store.phase),
        child: switch (store.phase) {
          Phase.loading => const SplashScreen(),
          Phase.signedOut => const SignInScreen(),
          Phase.pending => const PendingScreen(),
          Phase.disabled => const DisabledScreen(),
          Phase.failed => const FailedScreen(),
          Phase.active => const AppShell(),
        },
      ),
    );
  }
}
