# SAMAI — Arquitectura del MVP

## 1. Decisiones clave

| Decisión | Elección | Por qué |
|---|---|---|
| Plataforma | Flutter 3.29+ (Android, minSdk 29) | Un código, Android 10+ trae cifrado del dispositivo y biometría estable |
| Dónde viven los datos | **Solo en el dispositivo** (offline-first) | Minimización (Ley 29733): sin servidor no hay filtraciones masivas, ni transferencias, ni cuentas |
| Cifrado en reposo | Hive CE + AES-256; llaves en Android Keystore (flutter_secure_storage) | Estándar, sin generación de código |
| Cifrado en tránsito | No hay tránsito de datos personales: la app **no declara permiso INTERNET**. Fase 2 (sincronización) → TLS 1.3 + certificate pinning | La mejor transmisión segura es la que no ocurre |
| Autenticación | Sin cuentas. Bloqueo local con PIN (hash SHA-256 iterado + sal) y/o biometría; Premium ligado a la cuenta de Google Play | No se recolecta correo ni contraseña |
| Seudonimización | Registros clínicos con `pseudoId` aleatorio; identidad (apodo, contacto) en otra caja con otra llave | Separa datos de ánimo de la identidad |
| Estado | Provider + ChangeNotifier | Simple y suficiente para un MVP |
| Audio | just_audio: segmentos `.wav/.m4a` en assets + `SilenceAudioSource` | Composición dinámica sin conexión |
| Pagos | in_app_purchase (Google Play Billing) | Requisito de Play para contenido digital |
| Riesgo clínico | Reglas deterministas en el dispositivo | Auditables por un profesional; sin IA opaca |

## 2. Capas

```
lib/
├── main.dart                 Arranque: abre almacén cifrado, providers, billing
├── app.dart                  MaterialApp, RootGate (flujo) y capa de bloqueo
├── core/                     Constantes (umbral, líneas de ayuda, producto) y tema
├── data/                     Modelos, almacén cifrado, repositorios, exportación
├── domain/                   Lógica pura y testeable
│   ├── audio_catalog.dart      27 segmentos + 13 ejercicios (3 gratis)
│   ├── session_composer.dart   Arma el audio según problema/contexto/duración
│   ├── recommender.dart        Sugiere por contexto, hora, emoción y temas
│   ├── progress.dart           Estadísticas semanales + resumen en lenguaje simple
│   └── risk_detector.dart      Umbral de ansiedad + palabras de riesgo
├── services/                 Google Play Billing, PIN/biometría
├── state/app_state.dart      Orquesta todo; ciclo de vida para re-bloquear
└── ui/                       Pantallas y widgets
```

La capa `domain/` no depende de Flutter UI: se prueba con `flutter test`.

## 3. Modelo de datos

Cuatro cajas Hive cifradas, tres llaves distintas:

| Caja | Llave | Contenido |
|---|---|---|
| `identity` | `k_identity` | `IdentityProfile { pseudoId, nickname?, emergencyName?, emergencyPhone? }` |
| `moods` | `k_clinical` | `MoodEntry { id, pseudoId, at, anxiety 0-10, emotion, note?, context? }` |
| `sessions` | `k_clinical` | `SessionRecord { id, pseudoId, at, exerciseId, title, problem, plannedSeconds, completed }` |
| `settings` | `k_settings` | `ConsentRecord { version, acceptedAt, adultConfirmed, privacyPolicyAccepted, sensitiveDataConsent }`, temas, PIN (hash + sal), biometría, `crisisActive`, caché de Premium |

Enumeraciones: `Problem` (anticipatoria, academico, laboral, insomnio, rumiacion), `Technique` (respiracion, defusion, valores, aceptacion, accion), `UserContext` (trabajando, estudiando, receso), `Emotion` (9 valores).

Contenido (estático, en código): `Segment { id, role intro|core|cierre, technique, problems, contexts, seconds, title, script }` y `Exercise { id, title, problem, focus, minutes, isFree, anchors }`.

## 4. Composición del audio personalizado

1. **Intro y cierre**: primero por problema (insomnio → `intro_noche` / `cierre_dormir`), luego por contexto (trabajando, estudiando, receso), si no el genérico.
2. **Anclas**: segmentos que dan identidad a un ejercicio de la biblioteca.
3. **Plan por problema**: cada problema tiene un orden de técnicas (insomnio no incluye "acción" para no activar de noche). Se elige un segmento por técnica: primero los específicos del problema y, entre ellos, el de duración más cercana a la cuota de tiempo restante.
4. **Relleno**: si sobra tiempo se agregan más segmentos que encajen.
5. **Silencios** repartidos entre segmentos (máx. 60 s cada uno).
6. **Orden ACT**: respiración → defusión → aceptación → valores → acción.

Garantías (probadas en `test/domain_test.dart`): nunca supera los 2/5/10 min elegidos y siempre tiene intro, al menos un segmento central y cierre.

## 5. Recomendador

Puntaje por problema: noche (22–5 h) → insomnio; estudiando → académico; trabajando → laboral; mañana laboral/estudio → anticipatoria; última emoción < 12 h (preocupación/miedo → anticipatoria; culpa/tristeza/enojo/frustración → rumiación); +1 por cada tema elegido en el onboarding. Cada sugerencia muestra su "por qué". Usuarios gratuitos reciben el ejercicio gratuito más cercano.

## 6. Flujo de pantallas

```
Bienvenida (3 páginas) → Consentimiento informado → Personalización (temas, apodo, contacto)
→ Inicio [Hoy | Biblioteca | Progreso | Ajustes] + aviso permanente
     Hoy ─ Registro de ánimo ──(ansiedad ≥ 9 o palabras de riesgo)──► Protocolo de ayuda
      │                                                              (ejercicios en pausa)
      └ Sugerencias ─► Reproductor ─► "¿Cómo te sientes ahora?"
     Biblioteca ─ filtros por problema ─ ejercicios (3 gratis) ─ "Sesión a tu medida" (Premium)
     Progreso ─ gráfico 7 días vs. semana anterior ─ resumen ─ reporte (Premium)
     Ajustes ─ Suscripción ─ PIN/biometría ─ contacto ─ exportar ─ eliminar todo
Bloqueo PIN/biometría: capa superpuesta al abrir y tras 30 s en segundo plano
```

## 7. Seguridad clínica

- Aviso permanente "no es tratamiento médico" en la barra inferior y en el reproductor.
- `RiskDetector`: `critical` si hay expresiones de ideación suicida/autolesión; `high` si ansiedad ≥ 9 o expresiones de desborde. Normaliza tildes y mayúsculas.
- Al detectar riesgo: pantalla de ayuda (Línea 113 opción 5, WhatsApp Infosalud, contacto de confianza, SAMU 106, Policía 105, Bomberos 116) y `crisisActive = true`: Inicio, Biblioteca y Reproductor muestran el bloque de ayuda en lugar de ejercicios hasta un nuevo registro sin riesgo.
- La lista de palabras debe ser revisada y ampliada por un psicólogo clínico antes de publicar. Prioriza sensibilidad sobre especificidad (puede dispararse con "me voy a matar estudiando"): es intencional.

## 8. Fase 2 (fuera del MVP)

- Sincronización opcional cifrada de extremo a extremo (cuenta anónima, servidor en región con nivel adecuado de protección, TLS 1.3 + pinning). Implica inscribir el banco de datos ante la ANPD, designar Oficial de Datos Personales y evaluar impacto.
- Validación del `purchaseToken` en servidor con Google Play Developer API y notificaciones RTDN.
- Recordatorios locales, más idiomas (quechua), audios grabados por locutores profesionales.
