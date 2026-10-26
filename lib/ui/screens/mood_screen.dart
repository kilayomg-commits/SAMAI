import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../domain/risk_detector.dart';
import '../../state/app_state.dart';
import 'crisis_screen.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});
  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  double _anxiety = 5;
  Emotion? _emotion;
  UserContext? _context;
  final _note = TextEditingController();
  bool _saving = false;

  static String describe(int v) {
    if (v <= 2) return 'Tranquilo';
    if (v <= 4) return 'Algo inquieto';
    if (v <= 6) return 'Ansiedad moderada';
    if (v <= 8) return 'Ansiedad alta';
    return 'Ansiedad muy alta';
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final state = context.read<AppState>();
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final risk = await state.addMood(
      anxiety: _anxiety.round(),
      emotion: _emotion!,
      note: _note.text,
      context: _context,
    );
    if (!mounted) return;
    if (risk == RiskLevel.none) {
      nav.pop();
      messenger.showSnackBar(
          const SnackBar(content: Text('Registro guardado. Gracias por tomarte este momento.')));
    } else {
      nav.pushReplacement(MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => CrisisScreen(level: risk)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = _anxiety.round();
    return Scaffold(
      appBar: AppBar(title: const Text('¿Cómo te sientes?')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Nivel de ansiedad ahora mismo'),
            const SizedBox(height: 8),
            Center(
              child: Text('$v',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Center(child: Text(describe(v))),
            Slider(
              value: _anxiety,
              min: 0,
              max: 10,
              divisions: 10,
              label: '$v',
              onChanged: (x) => setState(() => _anxiety = x),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('0 · nada'), Text('10 · máxima')],
            ),
            const SizedBox(height: 20),
            const Text('Emoción principal'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: Emotion.values
                  .map((e) => ChoiceChip(
                        label: Text(e.label),
                        selected: _emotion == e,
                        onSelected: (_) => setState(() => _emotion = e),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text('¿Dónde estás? (opcional)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: UserContext.values
                  .map((c) => ChoiceChip(
                        label: Text(c.label),
                        selected: _context == c,
                        onSelected: (sel) =>
                            setState(() => _context = sel ? c : null),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _note,
              maxLength: 280,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota (opcional)',
                hintText: '¿Qué está pasando?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _emotion == null || _saving ? null : _save,
              child: const Text('Guardar registro'),
            ),
          ],
        ),
      ),
    );
  }
}
