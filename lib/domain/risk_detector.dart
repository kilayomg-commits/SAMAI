import '../core/constants.dart';

enum RiskLevel { none, high, critical }

/// Detección de riesgo basada en reglas (determinista y auditable).
///
/// - critical: el texto contiene expresiones de ideación suicida o autolesión.
/// - high: ansiedad >= umbral, o expresiones de desborde intenso.
///
/// IMPORTANTE: no es un instrumento clínico ni diagnostica. Su único fin es
/// mostrar el protocolo de ayuda (Línea 113, opción 5) y detener los
/// ejercicios. La lista debe revisarla un profesional de salud mental.
class RiskDetector {
  static const _critical = [
    'suicid',
    'matarme',
    'me quiero matar',
    'quitarme la vida',
    'acabar con mi vida',
    'no quiero vivir',
    'no quiero seguir viviendo',
    'quiero morir',
    'quisiera morir',
    'morirme',
    'mejor muerto',
    'mejor muerta',
    'estaria mejor muerto',
    'estaria mejor muerta',
    'hacerme daño',
    'hacerme dano',
    'lastimarme',
    'cortarme',
    'autolesion',
    'acabar con todo',
    'desaparecer para siempre',
    'no vale la pena vivir',
    'despedirme de todos',
    'ya no quiero despertar',
    'tomarme todas las pastillas',
  ];

  static const _high = [
    'ya no aguanto',
    'no puedo mas',
    'sin salida',
    'no tiene sentido nada',
    'ataque de panico',
    'me voy a volver loco',
    'me voy a volver loca',
    'no puedo respirar',
  ];

  static String normalize(String s) {
    const from = 'áàäâéèëêíìïîóòöôúùüûñ';
    const to = 'aaaaeeeeiiiioooouuuun';
    final lower = s.toLowerCase();
    final b = StringBuffer();
    for (final ch in lower.split('')) {
      final i = from.indexOf(ch);
      b.write(i >= 0 ? to[i] : ch);
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _containsAny(String text, List<String> patterns) {
    final t = normalize(text);
    return patterns.any((p) => t.contains(normalize(p)));
  }

  static RiskLevel evaluate({required int anxiety, String? text}) {
    if (text != null && text.trim().isNotEmpty) {
      if (_containsAny(text, _critical)) return RiskLevel.critical;
      if (_containsAny(text, _high)) return RiskLevel.high;
    }
    if (anxiety >= AppConstants.crisisAnxietyThreshold) return RiskLevel.high;
    return RiskLevel.none;
  }
}
