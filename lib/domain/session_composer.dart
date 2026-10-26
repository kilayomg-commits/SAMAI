import 'dart:math' as math;

import '../data/models.dart';
import 'audio_catalog.dart';

/// Elemento de la lista de reproducción: un segmento o un silencio.
class PlaylistItem {
  final Segment? segment;
  final int pauseSeconds;

  const PlaylistItem.segment(Segment this.segment) : pauseSeconds = 0;
  const PlaylistItem.pause(this.pauseSeconds) : segment = null;

  bool get isPause => segment == null;
  int get seconds => segment?.seconds ?? pauseSeconds;
}

class ComposedSession {
  final String exerciseId;
  final String title;
  final Problem problem;
  final int targetMinutes;
  final List<PlaylistItem> items;

  const ComposedSession({
    required this.exerciseId,
    required this.title,
    required this.problem,
    required this.targetMinutes,
    required this.items,
  });

  int get totalSeconds => items.fold(0, (s, i) => s + i.seconds);
  List<Segment> get segments =>
      items.where((i) => !i.isPause).map((i) => i.segment!).toList();
}

/// Arma un audio combinando segmentos pregrabados según problema, contexto,
/// duración disponible y técnica preferida.
///
/// Reglas:
/// 1. Intro y cierre se eligen por problema (p. ej. insomnio) y luego por
///    contexto (trabajando / estudiando / receso); si no, el genérico.
/// 2. Se agregan los segmentos ancla del ejercicio (si los tiene). Luego se
///    recorre el "plan" de técnicas del problema (la técnica foco tiene
///    prioridad para entrar) y se toma un segmento por técnica, priorizando los específicos
///    del problema y la duración más cercana a la "cuota" de tiempo restante.
/// 3. Si sobra tiempo, se agregan más segmentos que encajen.
/// 4. El tiempo restante se reparte como silencios entre segmentos (máx. 60 s).
/// 5. El orden final sigue el flujo ACT: respiración → defusión/aceptación →
///    valores → acción.
class SessionComposer {
  static const plans = <Problem, List<Technique>>{
    Problem.anticipatoria: [
      Technique.respiracion,
      Technique.defusion,
      Technique.aceptacion,
      Technique.valores,
      Technique.accion,
    ],
    Problem.academico: [
      Technique.respiracion,
      Technique.aceptacion,
      Technique.valores,
      Technique.defusion,
      Technique.accion,
    ],
    Problem.laboral: [
      Technique.respiracion,
      Technique.aceptacion,
      Technique.valores,
      Technique.accion,
      Technique.defusion,
    ],
    // Sin "acción" de noche: no se invita a activarse antes de dormir.
    Problem.insomnio: [
      Technique.respiracion,
      Technique.aceptacion,
      Technique.defusion,
    ],
    Problem.rumiacion: [
      Technique.respiracion,
      Technique.defusion,
      Technique.valores,
      Technique.accion,
      Technique.aceptacion,
    ],
  };

  static const _flowOrder = [
    Technique.respiracion,
    Technique.defusion,
    Technique.aceptacion,
    Technique.valores,
    Technique.accion,
  ];

  static const maxPause = 60;

  final List<Segment> catalog;
  const SessionComposer([this.catalog = AudioCatalog.segments]);

  ComposedSession compose({
    required String exerciseId,
    required String title,
    required Problem problem,
    required int minutes,
    UserContext? context,
    Technique? focus,
    List<String> anchors = const [],
  }) {
    final budget = minutes * 60;
    final intro = _framer(SegmentRole.intro, problem, context);
    final cierre = _framer(SegmentRole.cierre, problem, context);
    var used = intro.seconds + cierre.seconds;

    final plan = [...plans[problem]!];
    if (focus != null && plan.contains(focus)) {
      plan
        ..remove(focus)
        ..insert(0, focus);
    }

    final chosen = <Segment>[];

    // Paso 0: segmentos ancla del ejercicio (le dan su identidad).
    for (final id in anchors) {
      final seg = catalog.where((x) => x.id == id).firstOrNull;
      if (seg != null && used + seg.seconds <= budget) {
        chosen.add(seg);
        used += seg.seconds;
      }
    }

    // Paso 1: un segmento por técnica del plan.
    for (var i = 0; i < plan.length; i++) {
      if (chosen.any((c) => c.technique == plan[i])) continue; // ya cubierta
      final remaining = budget - used;
      final share = remaining ~/ (plan.length - i);
      final pick = _best(plan[i], problem, context, chosen, remaining, share);
      if (pick != null) {
        chosen.add(pick);
        used += pick.seconds;
      }
    }

    // Paso 2: completar con más segmentos si sobra tiempo.
    while (true) {
      final remaining = budget - used;
      Segment? extra;
      for (final t in plan) {
        final c = _best(t, problem, context, chosen, remaining, remaining);
        if (c != null && (extra == null || c.seconds > extra.seconds)) {
          extra = c;
        }
      }
      if (extra == null) break;
      chosen.add(extra);
      used += extra.seconds;
    }

    // Orden según el flujo ACT: anclarse (respiración) → abrirse
    // (defusión/aceptación) → comprometerse (valores/acción).
    chosen.sort((a, b) => _flowOrder
        .indexOf(a.technique!)
        .compareTo(_flowOrder.indexOf(b.technique!)));

    // Silencios entre segmentos.
    final items = <PlaylistItem>[PlaylistItem.segment(intro)];
    final remaining = budget - used;
    final gaps = chosen.isEmpty ? 0 : chosen.length;
    final pauseEach =
        gaps == 0 ? 0 : math.max(0, math.min(maxPause, remaining ~/ gaps));
    for (final s in chosen) {
      items.add(PlaylistItem.segment(s));
      if (pauseEach >= 5) items.add(PlaylistItem.pause(pauseEach));
    }
    items.add(PlaylistItem.segment(cierre));

    return ComposedSession(
      exerciseId: exerciseId,
      title: title,
      problem: problem,
      targetMinutes: minutes,
      items: items,
    );
  }

  ComposedSession composeExercise(Exercise e, {UserContext? context}) =>
      compose(
        exerciseId: e.id,
        title: e.title,
        problem: e.problem,
        minutes: e.minutes,
        context: context,
        focus: e.focus,
        anchors: e.anchors,
      );

  bool _matches(Segment s, Problem p, UserContext? c) =>
      (s.problems.isEmpty || s.problems.contains(p)) &&
      (s.contexts.isEmpty || (c != null && s.contexts.contains(c)));

  Segment _framer(SegmentRole role, Problem p, UserContext? c) {
    final options = catalog.where((s) => s.role == role).toList();
    // 1) específico del problema
    for (final s in options) {
      if (s.problems.contains(p)) return s;
    }
    // 2) específico del contexto
    if (c != null) {
      for (final s in options) {
        if (s.problems.isEmpty && s.contexts.contains(c)) return s;
      }
    }
    // 3) genérico
    return options.firstWhere(
        (s) => s.problems.isEmpty && s.contexts.isEmpty,
        orElse: () => options.first);
  }

  Segment? _best(Technique t, Problem p, UserContext? c, List<Segment> taken,
      int remaining, int share) {
    final cands = catalog
        .where((s) =>
            s.role == SegmentRole.core &&
            s.technique == t &&
            !taken.contains(s) &&
            s.seconds <= remaining &&
            _matches(s, p, c))
        .toList();
    if (cands.isEmpty) return null;
    cands.sort((a, b) {
      if (a.isSpecific != b.isSpecific) return a.isSpecific ? -1 : 1;
      return (a.seconds - share).abs().compareTo((b.seconds - share).abs());
    });
    return cands.first;
  }
}
