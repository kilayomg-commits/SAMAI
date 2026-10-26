import '../data/models.dart';
import 'audio_catalog.dart';

class Suggestion {
  final Problem problem;
  final int minutes;
  final String reason;

  /// Para usuarios gratuitos: el ejercicio gratuito más cercano.
  final Exercise? freeExercise;

  const Suggestion({
    required this.problem,
    required this.minutes,
    required this.reason,
    this.freeExercise,
  });
}

/// Sugiere ejercicios según contexto, hora del día, tiempo disponible,
/// preocupaciones elegidas en el onboarding y la última emoción registrada.
/// Reglas simples y explicables (cada sugerencia muestra su "por qué").
class Recommender {
  static List<Suggestion> suggest({
    required UserContext context,
    required DateTime now,
    required int minutes,
    required List<Problem> concerns,
    MoodEntry? lastMood,
    int max = 3,
  }) {
    final scores = <Problem, double>{for (final p in Problem.values) p: 0};
    final reasons = <Problem, String>{};

    void add(Problem p, double w, String why) {
      scores[p] = scores[p]! + w;
      final current = reasons[p];
      if (current == null || w >= 2) reasons[p] = why;
    }

    final h = now.hour;
    final isNight = h >= 22 || h < 5;
    final isMorning = h >= 5 && h < 11;

    if (isNight) add(Problem.insomnio, 3, 'Es de noche: una práctica para descansar');

    switch (context) {
      case UserContext.estudiando:
        add(Problem.academico, 2.5, 'Estás estudiando');
      case UserContext.trabajando:
        add(Problem.laboral, 2.5, 'Estás trabajando');
      case UserContext.receso:
        add(Problem.rumiacion, 1, 'Aprovecha tu receso para soltar la mente');
    }

    if (isMorning && context != UserContext.receso) {
      add(Problem.anticipatoria, 1.5, 'Las mañanas suelen traer preocupación por el día');
    }

    if (lastMood != null && now.difference(lastMood.at).inHours < 12) {
      switch (lastMood.emotion) {
        case Emotion.preocupacion:
        case Emotion.miedo:
          add(Problem.anticipatoria, 2, 'Registraste ${lastMood.emotion.label.toLowerCase()} hace poco');
        case Emotion.culpa:
        case Emotion.tristeza:
        case Emotion.enojo:
        case Emotion.frustracion:
          add(Problem.rumiacion, 2, 'Registraste ${lastMood.emotion.label.toLowerCase()} hace poco');
        case Emotion.cansancio:
          if (isNight) add(Problem.insomnio, 1, 'Registraste cansancio');
        case Emotion.calma:
        case Emotion.alegria:
          break;
      }
    }

    for (final p in concerns) {
      add(p, 1, 'Es uno de los temas que elegiste');
    }

    // De día no se sugiere insomnio salvo que sea una preocupación elegida.
    if (!isNight && !concerns.contains(Problem.insomnio)) {
      scores[Problem.insomnio] = -1;
    }

    final ranked = Problem.values.where((p) => scores[p]! > 0).toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));
    if (ranked.isEmpty) ranked.add(Problem.anticipatoria);

    return ranked.take(max).map((p) {
      return Suggestion(
        problem: p,
        minutes: minutes,
        reason: reasons[p] ?? 'Recomendado para ti',
        freeExercise: _closestFree(p, minutes),
      );
    }).toList();
  }

  static Exercise _closestFree(Problem p, int minutes) {
    final free = AudioCatalog.exercises.where((e) => e.isFree).toList();
    final sameProblem = free.where((e) => e.problem == p).toList();
    final pool = sameProblem.isNotEmpty ? sameProblem : free;
    pool.sort((a, b) =>
        (a.minutes - minutes).abs().compareTo((b.minutes - minutes).abs()));
    return pool.first;
  }
}
