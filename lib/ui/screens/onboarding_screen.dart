import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  static const _pages = [
    (
      Icons.spa_outlined,
      'Hola, soy SAMAI',
      'Te acompaño con ejercicios breves de audio para manejar la ansiedad y el '
          'estrés del día a día: en el trabajo, en los estudios o en tu receso.'
    ),
    (
      Icons.self_improvement,
      'Basado en ACT',
      'La Terapia de Aceptación y Compromiso no busca que dejes de sentir: te '
          'ayuda a hacer espacio a lo difícil, tomar distancia de los pensamientos '
          'y moverte hacia lo que te importa.'
    ),
    (
      Icons.health_and_safety_outlined,
      'Importante',
      'SAMAI es una herramienta de apoyo al bienestar. No diagnostica ni '
          'reemplaza a un psicólogo o psiquiatra. Si sientes que estás en peligro, '
          'llama a la Línea 113, opción 5 (gratuita, 24 horas) o acude a emergencias.'
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _ctrl,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) {
                    final (icon, title, body) = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(icon,
                            size: 88,
                            color: Theme.of(context).colorScheme.primary),
                        const SizedBox(height: 24),
                        Text(title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 16),
                        Text(body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.all(4),
                    width: i == _page ? 20 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  if (last) {
                    context.read<AppState>().markIntroSeen();
                  } else {
                    _ctrl.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut);
                  }
                },
                child: Text(last ? 'Entendido, continuar' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
