import '../data/models.dart';

enum SegmentRole { intro, core, cierre }

/// Segmento pregrabado. El texto (`script`) es el guion para locución y se
/// muestra como subtítulo en el reproductor. [pausa] = silencio de 3-5 s.
class Segment {
  final String id;
  final SegmentRole role;
  final Technique? technique;
  final Set<Problem> problems; // vacío = sirve para cualquier problema
  final Set<UserContext> contexts; // vacío = cualquier contexto
  final int seconds; // duración de la locución final
  final String title;
  final String script;

  const Segment({
    required this.id,
    required this.role,
    this.technique,
    this.problems = const {},
    this.contexts = const {},
    required this.seconds,
    required this.title,
    required this.script,
  });

  String get asset => 'assets/audio/$id.wav';
  bool get isSpecific => problems.isNotEmpty;
}

/// Ejercicio predefinido de la biblioteca (combinación fija).
class Exercise {
  final String id;
  final String title;
  final String subtitle;
  final Problem problem;
  final Technique focus;
  final int minutes;
  final bool isFree;

  /// Segmentos que SIEMPRE forman parte del ejercicio (dan su identidad).
  final List<String> anchors;

  const Exercise({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.problem,
    required this.focus,
    required this.minutes,
    this.isFree = false,
    this.anchors = const [],
  });
}

class AudioCatalog {
  static const segments = <Segment>[
    // ------------------------- INTROS -------------------------
    Segment(
      id: 'intro_general',
      role: SegmentRole.intro,
      seconds: 20,
      title: 'Bienvenida',
      script: 'Hola. Este es un momento para ti. No tienes que hacerlo perfecto: '
          'solo seguir la voz lo mejor que puedas. Si en algún momento te sientes '
          'peor, puedes detenerte. [pausa]',
    ),
    Segment(
      id: 'intro_trabajando',
      role: SegmentRole.intro,
      contexts: {UserContext.trabajando},
      seconds: 20,
      title: 'Pausa en el trabajo',
      script: 'Estás en medio de tu jornada. Puedes hacer esto sentado en tu sitio, '
          'con los ojos abiertos si prefieres, mirando un punto fijo. Nadie tiene '
          'que notarlo. [pausa]',
    ),
    Segment(
      id: 'intro_estudiando',
      role: SegmentRole.intro,
      contexts: {UserContext.estudiando},
      seconds: 20,
      title: 'Pausa en el estudio',
      script: 'Deja un momento el cuaderno o la pantalla. No estás perdiendo tiempo: '
          'estás cuidando la mente con la que estudias. Apoya los pies en el piso. '
          '[pausa]',
    ),
    Segment(
      id: 'intro_receso',
      role: SegmentRole.intro,
      contexts: {UserContext.receso},
      seconds: 20,
      title: 'Tu receso',
      script: 'Tienes unos minutos de receso. Busca una postura cómoda, sentado o de pie. '
          'Si puedes, cierra los ojos; si no, baja la mirada. [pausa]',
    ),
    Segment(
      id: 'intro_noche',
      role: SegmentRole.intro,
      problems: {Problem.insomnio},
      seconds: 25,
      title: 'Antes de dormir',
      script: 'Acuéstate como te resulte cómodo. Esta práctica no busca obligarte a '
          'dormir: busca dejar de pelear con la noche. Deja que la cama te sostenga. '
          '[pausa]',
    ),

    // ---------------------- RESPIRACIÓN -----------------------
    Segment(
      id: 'resp_ancla_breve',
      role: SegmentRole.core,
      technique: Technique.respiracion,
      seconds: 60,
      title: 'Respiración ancla',
      script: 'Lleva la atención a tu respiración, sin cambiarla. Nota dónde la sientes '
          'más: la nariz, el pecho o el abdomen. [pausa] Si la mente se va, está bien. '
          'Nota a dónde se fue y vuelve con amabilidad al aire que entra y sale. '
          '[pausa] Tres respiraciones más, solo observando. [pausa]',
    ),
    Segment(
      id: 'resp_observar',
      role: SegmentRole.core,
      technique: Technique.respiracion,
      seconds: 90,
      title: 'Observar la respiración',
      script: 'Imagina que eres un científico curioso observando tu respiración por '
          'primera vez. ¿Es rápida o lenta? ¿Corta o profunda? No hay una forma correcta. '
          '[pausa] Nota la pequeña pausa al final de cada exhalación. [pausa] Cada vez '
          'que aparezca un pensamiento, di en silencio “pensando” y regresa a la '
          'respiración. [pausa]',
    ),
    Segment(
      id: 'resp_cuerpo',
      role: SegmentRole.core,
      technique: Technique.respiracion,
      seconds: 120,
      title: 'Respirar con todo el cuerpo',
      script: 'Amplía la atención: además de la respiración, nota los pies, las piernas, '
          'la espalda apoyada. [pausa] Imagina que el aire llega a cada zona que notas, '
          'sin necesidad de relajarla. [pausa] Si encuentras tensión, solo nómbrala: '
          '“aquí hay tensión”. Y sigue respirando junto a ella. [pausa] [pausa]',
    ),

    // ------------------------ DEFUSIÓN ------------------------
    Segment(
      id: 'def_tengo_el_pensamiento',
      role: SegmentRole.core,
      technique: Technique.defusion,
      seconds: 90,
      title: 'Tengo el pensamiento de…',
      script: 'Elige un pensamiento que te esté molestando, por ejemplo “no voy a poder”. '
          'Dilo en silencio tal cual. [pausa] Ahora agrégale al inicio: “Estoy teniendo '
          'el pensamiento de que no voy a poder”. [pausa] Y ahora: “Me doy cuenta de '
          'que estoy teniendo el pensamiento de que no voy a poder”. [pausa] Nota si '
          'cambia algo. El pensamiento sigue ahí, pero tú estás un paso más atrás. [pausa]',
    ),
    Segment(
      id: 'def_hojas_rio',
      role: SegmentRole.core,
      technique: Technique.defusion,
      seconds: 180,
      title: 'Hojas en el río',
      script: 'Imagina un río tranquilo con hojas que flotan en la corriente. [pausa] '
          'Cada vez que aparezca un pensamiento, una imagen o una preocupación, colócalo '
          'sobre una hoja y deja que se aleje a su propio ritmo. [pausa] No empujes las '
          'hojas ni las detengas. Si te enganchas con un pensamiento y te vas, está bien: '
          'nota que te fuiste y vuelve a la orilla. [pausa] [pausa] [pausa]',
    ),
    Segment(
      id: 'def_nombrar_historia',
      role: SegmentRole.core,
      technique: Technique.defusion,
      seconds: 90,
      title: 'Ponle nombre a la historia',
      script: 'Nuestra mente suele contar las mismas historias. Si esta preocupación '
          'fuera una película, ¿cómo se llamaría? Quizás “La historia de que todo va a '
          'salir mal”. [pausa] La próxima vez que aparezca, puedes decir: “Ah, otra vez '
          'esta película”. No tienes que discutir con ella ni creerle. [pausa]',
    ),

    // ----------------------- ACEPTACIÓN -----------------------
    Segment(
      id: 'acep_expansion',
      role: SegmentRole.core,
      technique: Technique.aceptacion,
      seconds: 150,
      title: 'Hacer espacio',
      script: 'Busca en tu cuerpo dónde sientes más la ansiedad o el estrés. [pausa] '
          'Obsérvala como si fuera un objeto: ¿qué forma tiene? ¿Qué tamaño? ¿Es '
          'caliente o fría? [pausa] Respira hacia esa zona y, en lugar de empujarla, '
          'imagina que le haces un poco de espacio alrededor. [pausa] No tiene que '
          'gustarte. Solo permitir que esté ahí mientras sigues respirando. [pausa] [pausa]',
    ),
    Segment(
      id: 'acep_ola',
      role: SegmentRole.core,
      technique: Technique.aceptacion,
      seconds: 120,
      title: 'Surfear la ola',
      script: 'Las emociones suben y bajan como las olas del mar. [pausa] Nota la '
          'intensidad de lo que sientes ahora, del 0 al 10. [pausa] En vez de luchar '
          'contra la ola, imagina que la surfeas: subes con ella, sabiendo que en algún '
          'momento baja. [pausa] Sigue observando cómo cambia, aunque sea un poquito. [pausa]',
    ),

    // ------------------------ VALORES -------------------------
    Segment(
      id: 'val_brujula',
      role: SegmentRole.core,
      technique: Technique.valores,
      seconds: 120,
      title: 'Tu brújula',
      script: 'Piensa en una persona a la que admiras. ¿Qué cualidades tiene? [pausa] '
          'Ahora pregúntate: ¿qué tipo de persona quiero ser yo, incluso en días '
          'difíciles? Quizás alguien amable, valiente, responsable. [pausa] Esos son tus '
          'valores: no son metas que se terminan, son direcciones, como una brújula. [pausa]',
    ),
    Segment(
      id: 'val_estudio',
      role: SegmentRole.core,
      technique: Technique.valores,
      problems: {Problem.academico},
      seconds: 90,
      title: '¿Para qué estudio?',
      script: 'Más allá de la nota, ¿para qué estás estudiando esto? Tal vez por tu '
          'familia, por aprender, por el futuro que quieres construir. [pausa] Nota que '
          'el estrés aparece justamente porque esto te importa. [pausa] Puedes llevar '
          'contigo el estrés y también ese “para qué”. [pausa]',
    ),
    Segment(
      id: 'val_trabajo',
      role: SegmentRole.core,
      technique: Technique.valores,
      problems: {Problem.laboral},
      seconds: 90,
      title: '¿Qué quiero aportar?',
      script: 'Piensa en tu trabajo. Más allá de los pendientes, ¿qué quieres aportar? '
          '¿Cómo quieres tratar a tus compañeros, a tus clientes, a ti mismo? [pausa] '
          'Elige una palabra que te represente hoy: por ejemplo, “respeto”, “esfuerzo”, '
          '“calma”. [pausa] Llévala contigo a la siguiente tarea. [pausa]',
    ),

    // ------------------- ACCIÓN COMPROMETIDA ------------------
    Segment(
      id: 'acc_paso_pequeno',
      role: SegmentRole.core,
      technique: Technique.accion,
      seconds: 90,
      title: 'Un paso pequeño',
      script: 'Piensa en una acción pequeña que puedas hacer en los próximos diez minutos '
          'y que vaya en la dirección de lo que te importa. Algo muy concreto: escribir '
          'un correo, leer una página, tomar agua. [pausa] Imagínate haciéndolo, aun con '
          'la incomodidad presente. [pausa] No necesitas sentirte bien para dar el paso. [pausa]',
    ),
    Segment(
      id: 'acc_mientras_tanto',
      role: SegmentRole.core,
      technique: Technique.accion,
      seconds: 60,
      title: 'Y mientras tanto…',
      script: 'Completa la frase: “Me siento ansioso, y mientras tanto voy a…”. [pausa] '
          'Fíjate en la palabra “y”, no “pero”. La emoción y la acción pueden ir juntas. '
          '[pausa]',
    ),

    // --------------- ESPECÍFICOS POR PROBLEMA -----------------
    Segment(
      id: 'anticip_aqui_ahora',
      role: SegmentRole.core,
      technique: Technique.defusion,
      problems: {Problem.anticipatoria},
      seconds: 90,
      title: 'El futuro y el ahora',
      script: 'La mente ansiosa viaja al futuro y trae imágenes de lo que podría pasar. '
          '[pausa] Nota: “mi mente está prediciendo”. [pausa] Ahora nombra cinco cosas '
          'que puedes ver, cuatro que puedes tocar y tres que puedes escuchar, aquí y '
          'ahora. [pausa] [pausa] El futuro todavía no llega; este momento sí está aquí. [pausa]',
    ),
    Segment(
      id: 'rum_volver_presente',
      role: SegmentRole.core,
      technique: Technique.defusion,
      problems: {Problem.rumiacion},
      seconds: 90,
      title: 'Bajar del carrusel',
      script: 'Cuando le damos vueltas a lo mismo, es como estar en un carrusel que no '
          'para. [pausa] Pregúntate con sinceridad: ¿pensar más en esto me está ayudando '
          'a resolverlo, o solo me hace girar? [pausa] Si solo giras, agradece a tu mente '
          'por intentar protegerte: “gracias, mente”. Y vuelve a lo que tienes delante. [pausa]',
    ),
    Segment(
      id: 'insom_soltar',
      role: SegmentRole.core,
      technique: Technique.aceptacion,
      problems: {Problem.insomnio},
      seconds: 150,
      title: 'Soltar el esfuerzo',
      script: 'Esforzarse por dormir suele mantenernos despiertos. [pausa] Dite: “está '
          'bien estar despierto ahora; el descanso también cuenta”. [pausa] Recorre el '
          'cuerpo desde los pies hasta la cabeza, notando el peso de cada parte sobre la '
          'cama. [pausa] [pausa] Si llegan pensamientos, déjalos pasar como nubes en un '
          'cielo oscuro. [pausa] [pausa]',
    ),
    Segment(
      id: 'acad_examen',
      role: SegmentRole.core,
      technique: Technique.aceptacion,
      problems: {Problem.academico},
      seconds: 90,
      title: 'Antes del examen',
      script: 'Es normal sentir nervios antes de un examen o una exposición: tu cuerpo se '
          'está preparando. [pausa] Nota el corazón, las manos, el estómago. En vez de '
          'pedir que se vayan, dite: “es energía para rendir”. [pausa] Has estudiado lo que '
          'pudiste. Ahora lo importante es estar presente en cada pregunta. [pausa]',
    ),
    Segment(
      id: 'lab_sobrecarga',
      role: SegmentRole.core,
      technique: Technique.aceptacion,
      problems: {Problem.laboral},
      seconds: 90,
      title: 'Cuando todo es urgente',
      script: 'Cuando todo parece urgente, la mente intenta sostener todas las tareas a la '
          'vez. [pausa] Imagina que las dejas un momento sobre una mesa. Siguen ahí, no '
          'desaparecen. [pausa] Nota tu respiración y elige solo la siguiente tarea, una '
          'sola. Las demás pueden esperar unos minutos. [pausa]',
    ),

    // ------------------------ CIERRES -------------------------
    Segment(
      id: 'cierre_general',
      role: SegmentRole.cierre,
      seconds: 15,
      title: 'Cierre',
      script: 'Poco a poco, vuelve a notar el lugar donde estás. Gracias por regalarte '
          'este momento. [pausa]',
    ),
    Segment(
      id: 'cierre_volver_tarea',
      role: SegmentRole.cierre,
      contexts: {UserContext.trabajando, UserContext.estudiando},
      seconds: 15,
      title: 'Volver a la tarea',
      script: 'Mueve un poco las manos y los hombros. Cuando estés listo, vuelve a tu tarea '
          'con lo que elegiste. No tienes que esperar a sentirte perfecto. [pausa]',
    ),
    Segment(
      id: 'cierre_receso',
      role: SegmentRole.cierre,
      contexts: {UserContext.receso},
      seconds: 15,
      title: 'Cierre del receso',
      script: 'Estira el cuerpo si lo necesitas. Disfruta lo que queda de tu receso. [pausa]',
    ),
    Segment(
      id: 'cierre_dormir',
      role: SegmentRole.cierre,
      problems: {Problem.insomnio},
      seconds: 30,
      title: 'Quedarte en el descanso',
      script: 'No necesitas abrir los ojos ni hacer nada más. Puedes quedarte aquí, '
          'descansando, dejando que el sueño llegue cuando quiera llegar. [pausa] [pausa]',
    ),
  ];

  /// Biblioteca de ejercicios. Los 3 primeros son gratuitos.
  static const exercises = <Exercise>[
    Exercise(
      id: 'free_respira2',
      title: 'Respiración ancla',
      subtitle: 'Para bajar revoluciones en 2 minutos',
      problem: Problem.anticipatoria,
      focus: Technique.respiracion,
      minutes: 2,
      anchors: ['resp_ancla_breve'],
      isFree: true,
    ),
    Exercise(
      id: 'free_defusion5',
      title: 'Tengo el pensamiento de…',
      subtitle: 'Toma distancia de los pensamientos que se repiten',
      problem: Problem.rumiacion,
      focus: Technique.defusion,
      minutes: 5,
      anchors: ['def_tengo_el_pensamiento'],
      isFree: true,
    ),
    Exercise(
      id: 'free_pausa5',
      title: 'Pausa para el estrés',
      subtitle: 'Hacer espacio a la tensión y volver a lo importante',
      problem: Problem.academico,
      focus: Technique.aceptacion,
      minutes: 5,
      anchors: ['acep_expansion'],
      isFree: true,
    ),
    // ---- Premium ----
    Exercise(
      id: 'p_anticip_5',
      title: 'El futuro y el ahora',
      subtitle: 'Cuando la mente se adelanta a lo peor',
      problem: Problem.anticipatoria,
      focus: Technique.defusion,
      minutes: 5,
      anchors: ['anticip_aqui_ahora'],
    ),
    Exercise(
      id: 'p_anticip_10',
      title: 'Surfear la ansiedad',
      subtitle: 'Práctica completa de aceptación',
      problem: Problem.anticipatoria,
      focus: Technique.aceptacion,
      minutes: 10,
      anchors: ['acep_ola'],
    ),
    Exercise(
      id: 'p_acad_examen',
      title: 'Antes del examen',
      subtitle: 'Nervios convertidos en energía para rendir',
      problem: Problem.academico,
      focus: Technique.aceptacion,
      minutes: 5,
      anchors: ['acad_examen'],
    ),
    Exercise(
      id: 'p_acad_valores',
      title: '¿Para qué estudio?',
      subtitle: 'Reconecta con tus razones',
      problem: Problem.academico,
      focus: Technique.valores,
      minutes: 10,
      anchors: ['val_estudio'],
    ),
    Exercise(
      id: 'p_lab_sobrecarga',
      title: 'Cuando todo es urgente',
      subtitle: 'Una tarea a la vez',
      problem: Problem.laboral,
      focus: Technique.aceptacion,
      minutes: 5,
      anchors: ['lab_sobrecarga'],
    ),
    Exercise(
      id: 'p_lab_valores',
      title: 'Lo que quiero aportar',
      subtitle: 'Valores y acción en el trabajo',
      problem: Problem.laboral,
      focus: Technique.valores,
      minutes: 10,
      anchors: ['val_trabajo', 'acc_paso_pequeno'],
    ),
    Exercise(
      id: 'p_insom_5',
      title: 'Soltar el esfuerzo',
      subtitle: 'Dejar de pelear con la noche',
      problem: Problem.insomnio,
      focus: Technique.aceptacion,
      minutes: 5,
      anchors: ['insom_soltar'],
    ),
    Exercise(
      id: 'p_insom_10',
      title: 'Hojas en el río nocturno',
      subtitle: 'Pensamientos que pasan antes de dormir',
      problem: Problem.insomnio,
      focus: Technique.defusion,
      minutes: 10,
      anchors: ['def_hojas_rio'],
    ),
    Exercise(
      id: 'p_rum_5',
      title: 'Bajar del carrusel',
      subtitle: 'Cuando le das vueltas a lo mismo',
      problem: Problem.rumiacion,
      focus: Technique.defusion,
      minutes: 5,
      anchors: ['rum_volver_presente'],
    ),
    Exercise(
      id: 'p_rum_10',
      title: 'Un paso pequeño',
      subtitle: 'De la rumiación a la acción',
      problem: Problem.rumiacion,
      focus: Technique.accion,
      minutes: 10,
      anchors: ['acc_paso_pequeno'],
    ),
  ];

  static Exercise? exerciseById(String id) {
    for (final e in exercises) {
      if (e.id == id) return e;
    }
    return null;
  }
}
