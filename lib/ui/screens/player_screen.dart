import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../domain/session_composer.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'mood_screen.dart';

/// Reproduce la sesión armada: segmentos pregrabados + silencios, en orden.
/// Muestra el guion del segmento actual como subtítulo (accesibilidad).
class PlayerScreen extends StatefulWidget {
  final ComposedSession session;
  const PlayerScreen({super.key, required this.session});
  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _player = AudioPlayer();
  final _subs = <StreamSubscription<dynamic>>[];
  int _index = 0;
  bool _playing = false;
  bool _finished = false;
  bool _recorded = false;
  String? _error;
  late final AppState _app;

  @override
  void initState() {
    super.initState();
    _app = context.read<AppState>();
    _load();
  }

  Future<void> _load() async {
    final sources = widget.session.items
        .map<AudioSource>((i) => i.isPause
            ? SilenceAudioSource(duration: Duration(seconds: i.pauseSeconds))
            : AudioSource.asset(i.segment!.asset))
        .toList();
    try {
      await _player.setAudioSources(sources);
    } catch (e) {
      if (mounted) setState(() => _error = 'No se pudo cargar el audio.');
      return;
    }
    _subs.add(_player.currentIndexStream.listen((i) {
      if (i != null && mounted) setState(() => _index = i);
    }));
    _subs.add(_player.playerStateStream.listen((st) {
      if (!mounted) return;
      setState(() => _playing = st.playing);
      if (st.processingState == ProcessingState.completed && !_finished) {
        _finished = true;
        _player.pause();
        _record(completed: true);
        _showDone();
      }
    }));
    _player.play();
  }

  Future<void> _record({required bool completed}) async {
    if (_recorded) return;
    _recorded = true;
    await _app.recordSession(
          exerciseId: widget.session.exerciseId,
          title: widget.session.title,
          problem: widget.session.problem,
          plannedSeconds: widget.session.totalSeconds,
          completed: completed,
        );
  }

  void _showDone() {
    showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Bien hecho'),
        content: const Text(
            'Te diste un momento para ti. ¿Quieres registrar cómo te sientes ahora?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dCtx).pop();
              Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MoodScreen()));
            },
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Si sale antes de terminar y escuchó algo, se guarda como incompleta.
    if (!_recorded && _index > 0) {
      _recorded = true;
      _app.recordSession(
            exerciseId: widget.session.exerciseId,
            title: widget.session.title,
            problem: widget.session.problem,
            plannedSeconds: widget.session.totalSeconds,
            completed: false,
          );
    }
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    super.dispose();
  }

  String _fmt(int secs) =>
      '${secs ~/ 60}:${(secs % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final items = widget.session.items;
    final current = items[math.max(0, math.min(_index, items.length - 1))];
    final segCount = widget.session.segments.length;
    final segIndex = math.max(1,
        math.min(segCount, items.take(_index + 1).where((i) => !i.isPause).length));
    final crisis = context.watch<AppState>().crisisActive;

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.title)),
      bottomNavigationBar: const DisclaimerBanner(),
      body: SafeArea(
        child: crisis
            ? const Padding(
                padding: EdgeInsets.all(20), child: CrisisBlockCard())
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                        '${widget.session.problem.label} · ~${_fmt(widget.session.totalSeconds)}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 24),
                    LinearProgressIndicator(
                      value: (_index + (_finished ? 1 : 0)) / items.length,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(height: 8),
                    Text('Parte $segIndex de $segCount'),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  current.isPause
                                      ? 'Silencio'
                                      : current.segment!.title,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  current.isPause
                                      ? 'Quédate con la práctica a tu ritmo. '
                                          'La voz volverá en unos segundos.'
                                      : current.segment!.script
                                          .replaceAll('[pausa]', '…'),
                                  style: const TextStyle(
                                      fontSize: 17, height: 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.red)),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 36,
                          onPressed: _index > 0
                              ? () => _player.seekToPrevious()
                              : null,
                          icon: const Icon(Icons.skip_previous),
                        ),
                        const SizedBox(width: 16),
                        IconButton.filled(
                          iconSize: 48,
                          onPressed: _finished
                              ? null
                              : () =>
                                  _playing ? _player.pause() : _player.play(),
                          icon: Icon(_playing ? Icons.pause : Icons.play_arrow),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          iconSize: 36,
                          onPressed: _index < items.length - 1
                              ? () => _player.seekToNext()
                              : null,
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
