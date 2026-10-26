// Modelo de datos de SAMAI.
//
// Principio de seudonimización: los registros clínicos (ánimo, sesiones) NO
// contienen nombre, teléfono ni ningún identificador directo. Solo llevan el
// `pseudoId` aleatorio del dispositivo. Los datos identificables (apodo,
// contacto de emergencia) viven en una caja separada con otra llave de cifrado.

enum Problem { anticipatoria, academico, laboral, insomnio, rumiacion }

extension ProblemX on Problem {
  String get label => switch (this) {
        Problem.anticipatoria => 'Ansiedad anticipatoria',
        Problem.academico => 'Estrés académico',
        Problem.laboral => 'Estrés laboral',
        Problem.insomnio => 'Insomnio',
        Problem.rumiacion => 'Rumiación',
      };

  String get hint => switch (this) {
        Problem.anticipatoria => 'Preocupación por lo que podría pasar',
        Problem.academico => 'Exámenes, tareas, exposiciones',
        Problem.laboral => 'Carga de trabajo, jefes, plazos',
        Problem.insomnio => 'Dificultad para dormir o descansar',
        Problem.rumiacion => 'Darle vueltas a lo mismo una y otra vez',
      };
}

enum Technique { respiracion, defusion, valores, aceptacion, accion }

extension TechniqueX on Technique {
  String get label => switch (this) {
        Technique.respiracion => 'Respiración consciente',
        Technique.defusion => 'Defusión',
        Technique.valores => 'Valores',
        Technique.aceptacion => 'Aceptación',
        Technique.accion => 'Acción comprometida',
      };
}

enum UserContext { trabajando, estudiando, receso }

extension UserContextX on UserContext {
  String get label => switch (this) {
        UserContext.trabajando => 'Trabajando',
        UserContext.estudiando => 'Estudiando',
        UserContext.receso => 'En receso',
      };
}

enum Emotion {
  calma,
  preocupacion,
  miedo,
  tristeza,
  enojo,
  frustracion,
  cansancio,
  culpa,
  alegria
}

extension EmotionX on Emotion {
  String get label => switch (this) {
        Emotion.calma => 'Calma',
        Emotion.preocupacion => 'Preocupación',
        Emotion.miedo => 'Miedo',
        Emotion.tristeza => 'Tristeza',
        Emotion.enojo => 'Enojo',
        Emotion.frustracion => 'Frustración',
        Emotion.cansancio => 'Cansancio',
        Emotion.culpa => 'Culpa',
        Emotion.alegria => 'Alegría',
      };
}

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

/// Registro diario de ánimo (dato sensible de salud).
class MoodEntry {
  final String id;
  final String pseudoId;
  final DateTime at;
  final int anxiety; // 0-10
  final Emotion emotion;
  final String? note;
  final UserContext? context;

  const MoodEntry({
    required this.id,
    required this.pseudoId,
    required this.at,
    required this.anxiety,
    required this.emotion,
    this.note,
    this.context,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pseudoId': pseudoId,
        'at': at.toIso8601String(),
        'anxiety': anxiety,
        'emotion': emotion.name,
        'note': note,
        'context': context?.name,
      };

  factory MoodEntry.fromMap(Map<String, dynamic> m) => MoodEntry(
        id: m['id'] as String,
        pseudoId: m['pseudoId'] as String? ?? '',
        at: DateTime.parse(m['at'] as String),
        anxiety: (m['anxiety'] as num).toInt(),
        emotion: _enumByName(Emotion.values, m['emotion'], Emotion.calma),
        note: m['note'] as String?,
        context: m['context'] == null
            ? null
            : _enumByName(
                UserContext.values, m['context'], UserContext.receso),
      );
}

/// Sesión de audio realizada.
class SessionRecord {
  final String id;
  final String pseudoId;
  final DateTime at;
  final String exerciseId;
  final String title;
  final Problem problem;
  final int plannedSeconds;
  final bool completed;

  const SessionRecord({
    required this.id,
    required this.pseudoId,
    required this.at,
    required this.exerciseId,
    required this.title,
    required this.problem,
    required this.plannedSeconds,
    required this.completed,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'pseudoId': pseudoId,
        'at': at.toIso8601String(),
        'exerciseId': exerciseId,
        'title': title,
        'problem': problem.name,
        'plannedSeconds': plannedSeconds,
        'completed': completed,
      };

  factory SessionRecord.fromMap(Map<String, dynamic> m) => SessionRecord(
        id: m['id'] as String,
        pseudoId: m['pseudoId'] as String? ?? '',
        at: DateTime.parse(m['at'] as String),
        exerciseId: m['exerciseId'] as String,
        title: m['title'] as String? ?? '',
        problem:
            _enumByName(Problem.values, m['problem'], Problem.anticipatoria),
        plannedSeconds: (m['plannedSeconds'] as num?)?.toInt() ?? 0,
        completed: m['completed'] as bool? ?? false,
      );
}

/// Constancia del consentimiento informado (Ley 29733).
class ConsentRecord {
  final String version;
  final DateTime acceptedAt;
  final bool adultConfirmed;
  final bool privacyPolicyAccepted;
  final bool sensitiveDataConsent;

  const ConsentRecord({
    required this.version,
    required this.acceptedAt,
    required this.adultConfirmed,
    required this.privacyPolicyAccepted,
    required this.sensitiveDataConsent,
  });

  bool get isValid =>
      adultConfirmed && privacyPolicyAccepted && sensitiveDataConsent;

  Map<String, dynamic> toMap() => {
        'version': version,
        'acceptedAt': acceptedAt.toIso8601String(),
        'adultConfirmed': adultConfirmed,
        'privacyPolicyAccepted': privacyPolicyAccepted,
        'sensitiveDataConsent': sensitiveDataConsent,
      };

  factory ConsentRecord.fromMap(Map<String, dynamic> m) => ConsentRecord(
        version: m['version'] as String,
        acceptedAt: DateTime.parse(m['acceptedAt'] as String),
        adultConfirmed: m['adultConfirmed'] as bool? ?? false,
        privacyPolicyAccepted: m['privacyPolicyAccepted'] as bool? ?? false,
        sensitiveDataConsent: m['sensitiveDataConsent'] as bool? ?? false,
      );
}

/// Datos identificables (caja separada). Todo opcional.
class IdentityProfile {
  final String pseudoId;
  final String? nickname;
  final String? emergencyName;
  final String? emergencyPhone;

  const IdentityProfile({
    required this.pseudoId,
    this.nickname,
    this.emergencyName,
    this.emergencyPhone,
  });

  IdentityProfile copyWith({
    String? nickname,
    String? emergencyName,
    String? emergencyPhone,
  }) =>
      IdentityProfile(
        pseudoId: pseudoId,
        nickname: nickname ?? this.nickname,
        emergencyName: emergencyName ?? this.emergencyName,
        emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      );

  Map<String, dynamic> toMap() => {
        'pseudoId': pseudoId,
        'nickname': nickname,
        'emergencyName': emergencyName,
        'emergencyPhone': emergencyPhone,
      };

  factory IdentityProfile.fromMap(Map<String, dynamic> m) => IdentityProfile(
        pseudoId: m['pseudoId'] as String,
        nickname: m['nickname'] as String?,
        emergencyName: m['emergencyName'] as String?,
        emergencyPhone: m['emergencyPhone'] as String?,
      );
}
