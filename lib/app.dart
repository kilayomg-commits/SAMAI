import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'state/app_state.dart';
import 'ui/screens/consent_screen.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/lock_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/profile_setup_screen.dart';

class SamaiApp extends StatelessWidget {
  const SamaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAMAI',
      debugShowCheckedModeBanner: false,
      theme: SamaiTheme.light(),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const RootGate(),
      // El bloqueo se dibuja por encima de cualquier pantalla abierta.
      builder: (context, child) {
        final locked = context.select<AppState, bool>(
            (s) => s.locked && s.profileSetupDone);
        return Stack(fit: StackFit.expand, children: [
          if (child != null) child,
          if (locked) const Positioned.fill(child: LockScreen()),
        ]);
      },
    );
  }
}

/// Decide qué mostrar según el estado:
/// bienvenida → consentimiento → personalización → app (con bloqueo opcional).
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    if (!s.introSeen) return const OnboardingScreen();
    if (!s.hasValidConsent) return const ConsentScreen();
    if (!s.profileSetupDone) return const ProfileSetupScreen();
    return const HomeShell();
  }
}
