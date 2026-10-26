import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models.dart';
import '../../domain/audio_catalog.dart';
import '../../domain/recommender.dart';
import '../../domain/session_composer.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'library_screen.dart';
import 'mood_screen.dart';
import 'player_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  static const _tabs = [
    TodayTab(),
    LibraryScreen(),
    ProgressScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: _tabs)),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const DisclaimerBanner(),
          NavigationBar(
            selectedIndex: _tab,
            onDestinationSelected: (i) => setState(() => _tab = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.wb_sunny_outlined), label: 'Hoy'),
              NavigationDestination(icon: Icon(Icons.library_music_outlined), label: 'Biblioteca'),
              NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Progreso'),
              NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Ajustes'),
            ],
          ),
        ],
      ),
    );
  }
}

class TodayTab extends StatefulWidget {
  const TodayTab({super.key});
  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  int _minutes = 5;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  void _play(BuildContext context, ComposedSession session) =>
      Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlayerScreen(session: session)));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final ctx = s.settings.lastContext;
    final nick = s.identity.nickname;
    final today = s.todayMood;
    final suggestions = Recommender.suggest(
      context: ctx,
      now: DateTime.now(),
      minutes: _minutes,
      concerns: s.settings.concerns,
      lastMood: s.moods.latest(),
    );
    const composer = SessionComposer();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('${_greeting()}${nick != null ? ', $nick' : ''}',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const Icon(Icons.edit_note, size: 32),
            title: Text(today == null
                ? 'Registra cómo te sientes hoy'
                : 'Hoy: ansiedad ${today.anxiety}/10 · ${today.emotion.label}'),
            subtitle: Text(today == null
                ? 'Toma menos de 30 segundos'
                : 'Puedes registrar de nuevo si algo cambió'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MoodScreen())),
          ),
        ),
        if (s.crisisActive) ...[
          const SizedBox(height: 8),
          const CrisisBlockCard(),
        ] else ...[
          const SectionTitle('¿Dónde estás ahora?'),
          SegmentedButton<UserContext>(
            segments: UserContext.values
                .map((c) => ButtonSegment(value: c, label: Text(c.label)))
                .toList(),
            selected: {ctx},
            showSelectedIcon: false,
            onSelectionChanged: (v) => s.setLastContext(v.first),
          ),
          const SectionTitle('¿Cuánto tiempo tienes?'),
          Wrap(
            spacing: 8,
            children: AppConstants.durations
                .map((m) => ChoiceChip(
                      label: Text('$m min'),
                      selected: _minutes == m,
                      onSelected: (_) => setState(() => _minutes = m),
                    ))
                .toList(),
          ),
          const SectionTitle('Sugerido para ti'),
          ...suggestions.map((sug) {
            final premium = s.isPremium;
            final free = sug.freeExercise!;
            final title = premium ? sug.problem.label : free.title;
            final subtitle = premium
                ? '${sug.minutes} min · ${sug.reason}'
                : '${free.minutes} min · ${sug.reason}';
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.play_arrow),
                ),
                title: Text(title),
                subtitle: Text(subtitle),
                onTap: () => _play(
                  context,
                  premium
                      ? composer.compose(
                          exerciseId: 'custom_${sug.problem.name}_$_minutes',
                          title: sug.problem.label,
                          problem: sug.problem,
                          minutes: _minutes,
                          context: ctx,
                        )
                      : composer.composeExercise(free, context: ctx),
                ),
              ),
            );
          }),
          if (!s.isPremium)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton.icon(
                onPressed: () => openSubscription(context),
                icon: const Icon(Icons.auto_awesome),
                label: Text(
                    'Con Premium, cada audio se arma para tu momento '
                    '(${AudioCatalog.exercises.length} ejercicios + sesiones a medida)'),
              ),
            ),
        ],
      ],
    );
  }
}
