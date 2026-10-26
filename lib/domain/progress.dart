import '../data/models.dart';

class WeekStats {
  final DateTime start; // lunes 00:00
  final List<double?> dailyAvg; // 7 valores, null = sin registro
  final double? avgAnxiety;
  final int entries;
  final int sessionsCompleted;
  final int minutesPracticed;
  final Map<Emotion, int> emotions;

  const WeekStats({
    required this.start,
    required this.dailyAvg,
    required this.avgAnxiety,
    required this.entries,
    required this.sessionsCompleted,
    required this.minutesPracticed,
    required this.emotions,
  });

  Emotion? get topEmotion {
    if (emotions.isEmpty) return null;
    final sorted = emotions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class ProgressReport {
  final WeekStats current;
  final WeekStats previous;
  final String summary;
  const ProgressReport(this.current, this.previous, this.summary);

  /// Diferencia de ansiedad promedio (negativa = mejora).
  double? get anxietyDelta =>
      current.avgAnxiety == null || previous.avgAnxiety == null
          ? null
          : current.avgAnxiety! - previous.avgAnxiety!;
}

class ProgressCalculator {
  static DateTime weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static WeekStats _week(
      DateTime start, List<MoodEntry> moods, List<SessionRecord> sessions) {
    final end = start.add(const Duration(days: 7));
    bool inWeek(DateTime t) => !t.isBefore(start) && t.isBefore(end);

    final wm = moods.where((m) => inWeek(m.at)).toList();
    final ws = sessions.where((s) => inWeek(s.at)).toList();

    final daily = List<double?>.generate(7, (i) {
      final dayStart = start.add(Duration(days: i));
      final dayEnd = dayStart.add(const Duration(days: 1));
      final d = wm
          .where((m) => !m.at.isBefore(dayStart) && m.at.isBefore(dayEnd))
          .toList();
      if (d.isEmpty) return null;
      return d.fold<int>(0, (s, m) => s + m.anxiety) / d.length;
    });

    final emotions = <Emotion, int>{};
    for (final m in wm) {
      emotions[m.emotion] = (emotions[m.emotion] ?? 0) + 1;
    }

    final completed = ws.where((s) => s.completed).toList();
    return WeekStats(
      start: start,
      dailyAvg: daily,
      avgAnxiety: wm.isEmpty
          ? null
          : wm.fold<int>(0, (s, m) => s + m.anxiety) / wm.length,
      entries: wm.length,
      sessionsCompleted: completed.length,
      minutesPracticed:
          completed.fold<int>(0, (s, x) => s + x.plannedSeconds) ~/ 60,
      emotions: emotions,
    );
  }

  static ProgressReport build({
    required List<MoodEntry> moods,
    required List<SessionRecord> sessions,
    required DateTime now,
  }) {
    final start = weekStart(now);
    final current = _week(start, moods, sessions);
    final previous =
        _week(start.subtract(const Duration(days: 7)), moods, sessions);
    return ProgressReport(current, previous, _summary(current, previous));
  }

  static String _fmt(double v) => v.toStringAsFixed(1);

  /// Resumen en lenguaje simple, sin juicios ni términos clínicos.
  static String _summary(WeekStats c, WeekStats p) {
    if (c.entries == 0 && c.sessionsCompleted == 0) {
      return 'Aún no tienes registros esta semana. Un registro al día, aunque sea '
          'corto, te ayudará a ver cómo cambias con el tiempo.';
    }
    final parts = <String>[];

    if (c.avgAnxiety != null) {
      var line = 'Esta semana tu ansiedad promedio fue ${_fmt(c.avgAnxiety!)} de 10';
      if (p.avgAnxiety != null) {
        final d = c.avgAnxiety! - p.avgAnxiety!;
        final prev = _fmt(p.avgAnxiety!);
        if (d <= -1) {
          line += ', más baja que la semana pasada ($prev).';
        } else if (d >= 1) {
          line += ', más alta que la semana pasada ($prev). '
              'Hay semanas más pesadas que otras; eso no borra tu avance.';
        } else {
          line += ', parecida a la semana pasada ($prev).';
        }
      } else {
        line += '.';
      }
      parts.add(line);
    }

    if (c.sessionsCompleted > 0) {
      final n = c.sessionsCompleted;
      parts.add('Completaste $n ${n == 1 ? 'ejercicio' : 'ejercicios'} '
          '(${c.minutesPracticed} min en total)'
          '${p.sessionsCompleted > 0 ? '; la semana pasada fueron ${p.sessionsCompleted}' : ''}.');
    } else {
      parts.add('Esta semana todavía no completas un ejercicio. Prueba uno de 2 minutos.');
    }

    final top = c.topEmotion;
    if (top != null) {
      parts.add('La emoción que más registraste fue ${top.label.toLowerCase()}.');
    }

    final best = _bestDay(c);
    if (best != null) parts.add('Tu día más tranquilo fue el $best.');

    return parts.join(' ');
  }

  static const _days = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo'
  ];

  static String? _bestDay(WeekStats w) {
    int? idx;
    for (var i = 0; i < 7; i++) {
      final v = w.dailyAvg[i];
      if (v == null) continue;
      if (idx == null || v < w.dailyAvg[idx]!) idx = i;
    }
    final withData = w.dailyAvg.where((v) => v != null).length;
    return idx == null || withData < 2 ? null : _days[idx];
  }

  static String dayLabel(int i) => _days[i].substring(0, 2).toUpperCase();
}
