import 'package:flutter_test/flutter_test.dart';
import 'package:samai/data/models.dart';
import 'package:samai/domain/audio_catalog.dart';
import 'package:samai/domain/progress.dart';
import 'package:samai/domain/recommender.dart';
import 'package:samai/domain/risk_detector.dart';
import 'package:samai/domain/session_composer.dart';

void main() {
  group('RiskDetector', () {
    test('ansiedad baja sin texto = sin riesgo', () {
      expect(RiskDetector.evaluate(anxiety: 4), RiskLevel.none);
    });
    test('ansiedad >= 9 activa protocolo', () {
      expect(RiskDetector.evaluate(anxiety: 9), RiskLevel.high);
      expect(RiskDetector.evaluate(anxiety: 10), RiskLevel.high);
    });
    test('palabras de riesgo con tildes, mayúsculas o sin tildes', () {
      expect(RiskDetector.evaluate(anxiety: 2, text: 'A veces quiero MORIR'),
          RiskLevel.critical);
      expect(RiskDetector.evaluate(anxiety: 2, text: 'pienso en hacerme dano'),
          RiskLevel.critical);
      expect(RiskDetector.evaluate(anxiety: 2, text: 'Pensé en el SUICIDIO'),
          RiskLevel.critical);
    });
    test('texto cotidiano no dispara', () {
      expect(
          RiskDetector.evaluate(
              anxiety: 5, text: 'Mañana tengo examen de matemática'),
          RiskLevel.none);
    });
  });

  group('SessionComposer', () {
    const composer = SessionComposer();
    test('nunca supera la duración elegida y siempre tiene intro + cierre', () {
      for (final p in Problem.values) {
        for (final c in [null, ...UserContext.values]) {
          for (final m in [2, 5, 10]) {
            final s = composer.compose(
                exerciseId: 'x', title: 't', problem: p, minutes: m, context: c);
            expect(s.totalSeconds, lessThanOrEqualTo(m * 60));
            expect(s.items.first.segment!.role, SegmentRole.intro);
            expect(s.items.last.segment!.role, SegmentRole.cierre);
            expect(s.segments.where((x) => x.role == SegmentRole.core),
                isNotEmpty);
          }
        }
      }
    });
    test('insomnio usa intro/cierre nocturnos y no incluye acción', () {
      final s = composer.compose(
          exerciseId: 'x',
          title: 't',
          problem: Problem.insomnio,
          minutes: 10,
          context: UserContext.trabajando);
      expect(s.items.first.segment!.id, 'intro_noche');
      expect(s.items.last.segment!.id, 'cierre_dormir');
      expect(s.segments.any((x) => x.technique == Technique.accion), isFalse);
    });
    test('contexto estudiando usa intro de estudio', () {
      final s = composer.compose(
          exerciseId: 'x',
          title: 't',
          problem: Problem.academico,
          minutes: 5,
          context: UserContext.estudiando);
      expect(s.items.first.segment!.id, 'intro_estudiando');
    });
    test('los ejercicios incluyen sus segmentos ancla', () {
      for (final e in AudioCatalog.exercises) {
        final s = composer.composeExercise(e);
        for (final a in e.anchors) {
          expect(s.segments.map((x) => x.id), contains(a), reason: e.id);
        }
      }
    });
    test('hay exactamente 3 ejercicios gratuitos', () {
      expect(AudioCatalog.exercises.where((e) => e.isFree).length, 3);
    });
  });

  group('Recommender', () {
    test('de noche sugiere insomnio primero', () {
      final r = Recommender.suggest(
        context: UserContext.receso,
        now: DateTime(2026, 10, 20, 23, 30),
        minutes: 5,
        concerns: const [Problem.academico],
      );
      expect(r.first.problem, Problem.insomnio);
    });
    test('estudiando de día sugiere estrés académico', () {
      final r = Recommender.suggest(
        context: UserContext.estudiando,
        now: DateTime(2026, 10, 20, 15),
        minutes: 2,
        concerns: const [],
      );
      expect(r.first.problem, Problem.academico);
      expect(r.every((s) => s.freeExercise != null), isTrue);
    });
  });

  group('Progress', () {
    MoodEntry mood(DateTime at, int a) => MoodEntry(
        id: '$at', pseudoId: 'p', at: at, anxiety: a, emotion: Emotion.preocupacion);

    test('compara semana actual y anterior', () {
      final now = DateTime(2026, 10, 22); // jueves
      final r = ProgressCalculator.build(
        moods: [
          mood(DateTime(2026, 10, 20, 9), 4),
          mood(DateTime(2026, 10, 21, 9), 6),
          mood(DateTime(2026, 10, 13, 9), 8),
        ],
        sessions: const [],
        now: now,
      );
      expect(r.current.avgAnxiety, 5);
      expect(r.previous.avgAnxiety, 8);
      expect(r.anxietyDelta, -3);
      expect(r.summary, contains('más baja'));
      expect(r.current.start, DateTime(2026, 10, 19)); // lunes
    });
  });
}
