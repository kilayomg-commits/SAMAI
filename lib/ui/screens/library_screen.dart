import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models.dart';
import '../../domain/audio_catalog.dart';
import '../../domain/session_composer.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Problem? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final list = AudioCatalog.exercises
        .where((e) => _filter == null || e.problem == _filter)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Biblioteca', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (s.crisisActive)
          const CrisisBlockCard()
        else ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Todos'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...Problem.values.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(p.label),
                      selected: _filter == p,
                      onSelected: (_) => setState(() => _filter = p),
                    ),
                  )),
            ]),
          ),
          const SizedBox(height: 8),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: const Icon(Icons.tune, size: 30),
              title: const Text('Crear sesión a tu medida'),
              subtitle: const Text(
                  'Elige el problema, dónde estás, el tiempo y la técnica'),
              trailing: s.isPremium ? null : const PremiumLock(),
              onTap: () => s.isPremium
                  ? showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const _CustomSessionSheet(),
                    )
                  : openSubscription(context),
            ),
          ),
          ...list.map((e) {
            final locked = !e.isFree && !s.isPremium;
            return Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                title: Text(e.title),
                subtitle: Text(
                    '${e.minutes} min · ${e.focus.label}\n${e.subtitle}'),
                isThreeLine: true,
                trailing: locked
                    ? const PremiumLock()
                    : (e.isFree && !s.isPremium
                        ? const Text('Gratis')
                        : const Icon(Icons.play_circle_outline)),
                onTap: () {
                  if (locked) {
                    openSubscription(context);
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      session: const SessionComposer().composeExercise(e,
                          context: s.settings.lastContext),
                    ),
                  ));
                },
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _CustomSessionSheet extends StatefulWidget {
  const _CustomSessionSheet();
  @override
  State<_CustomSessionSheet> createState() => _CustomSessionSheetState();
}

class _CustomSessionSheetState extends State<_CustomSessionSheet> {
  Problem _problem = Problem.anticipatoria;
  UserContext _ctx = UserContext.receso;
  int _minutes = 5;
  Technique? _focus;

  @override
  void initState() {
    super.initState();
    _ctx = context.read<AppState>().settings.lastContext;
  }

  @override
  Widget build(BuildContext context) {
    final techniques = SessionComposer.plans[_problem]!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sesión a tu medida',
                style: Theme.of(context).textTheme.titleLarge),
            const SectionTitle('Lo que quiero trabajar'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: Problem.values
                  .map((p) => ChoiceChip(
                        label: Text(p.label),
                        selected: _problem == p,
                        onSelected: (_) => setState(() {
                          _problem = p;
                          if (_focus != null &&
                              !SessionComposer.plans[p]!.contains(_focus)) {
                            _focus = null;
                          }
                        }),
                      ))
                  .toList(),
            ),
            const SectionTitle('Dónde estoy'),
            Wrap(
              spacing: 8,
              children: UserContext.values
                  .map((c) => ChoiceChip(
                        label: Text(c.label),
                        selected: _ctx == c,
                        onSelected: (_) => setState(() => _ctx = c),
                      ))
                  .toList(),
            ),
            const SectionTitle('Tiempo'),
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
            const SectionTitle('Técnica preferida (opcional)'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: techniques
                  .map((t) => ChoiceChip(
                        label: Text(t.label),
                        selected: _focus == t,
                        onSelected: (sel) =>
                            setState(() => _focus = sel ? t : null),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Armar y escuchar'),
              onPressed: () {
                final session = const SessionComposer().compose(
                  exerciseId: 'custom_${_problem.name}_${_ctx.name}_$_minutes',
                  title: '${_problem.label} · $_minutes min',
                  problem: _problem,
                  minutes: _minutes,
                  context: _ctx,
                  focus: _focus,
                );
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (_) => PlayerScreen(session: session)));
              },
            ),
          ],
        ),
      ),
    );
  }
}
