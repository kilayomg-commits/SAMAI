# SAMAI — MVP Android (Flutter)

App de apoyo al bienestar para manejar ansiedad y estrés con ejercicios de Terapia de Aceptación y Compromiso (ACT), para jóvenes y adultos peruanos (18+) con ansiedad leve a moderada. **No es tratamiento médico ni diagnostica.**

## Qué incluye
| Función | Gratis | Premium (S/ 10/mes, prueba gratis) |
|---|---|---|
| Registro de ánimo (0–10, emoción, contexto, nota) | ✔ | ✔ |
| Progreso semanal: gráfico vs. semana anterior, ejercicios, resumen | ✔ | ✔ |
| Audios ACT | 3 | 13 + sesiones a medida |
| Audio armado por problema, contexto, hora y duración (2/5/10 min) | Sugerencia del gratuito más cercano | ✔ |
| Reporte detallado y compartible | — | ✔ |

Privacidad: datos solo en el celular, cifrados AES-256 (llaves en Android Keystore), seudonimizados, sin permiso INTERNET, sin backup en la nube, PIN/biometría, exportar y borrar todo. Seguridad clínica: aviso permanente y protocolo con Línea 113 opción 5 ante ansiedad ≥ 9 o palabras de riesgo, con ejercicios en pausa.

## Empezar
```bash
flutter create --org pe.samai --project-name samai --platforms android .
flutter pub get
flutter test
flutter run
```
Guía completa (APK, keystore, AAB, Play Console): **[docs/BUILD.md](docs/BUILD.md)**

## Documentación
- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md) — decisiones, capas, modelo de datos, compositor de audio, flujo de pantallas
- [docs/CUMPLIMIENTO.md](docs/CUMPLIMIENTO.md) — matriz Ley 29733 / D.S. 016-2024-JUS y checklist clínico
- [docs/DATA_SAFETY.md](docs/DATA_SAFETY.md) — respuestas para Seguridad de los datos y otras declaraciones de Play
- [docs/GUIONES_AUDIO.md](docs/GUIONES_AUDIO.md) — guiones de los 27 segmentos para locución
- [assets/legal/politica_privacidad.md](assets/legal/politica_privacidad.md) — política (completar razón social, RUC, correo)

## Pendientes antes de producción
1. Grabar los audios reales (los actuales son tonos de prueba).
2. Revisión de guiones y palabras de riesgo por psicólogo colegiado.
3. Completar datos del responsable en la política y publicarla en una URL.
4. Revisión legal de la política y el consentimiento.
5. Ícono y nombre definitivos; validación de compras en servidor (fase 2).
