# Declaración de Seguridad de los Datos (Google Play Console)

Play Console > Contenido de la app > Seguridad de los datos. Google define "recopilar" como **transmitir datos fuera del dispositivo**. SAMAI procesa todo localmente y no tiene permiso INTERNET, por lo que la declaración correcta es:

| Pregunta | Respuesta |
|---|---|
| ¿Tu app recopila o comparte alguno de los tipos de datos del usuario requeridos? | **No** |
| ¿Todos los datos del usuario recopilados están encriptados en tránsito? | No aplica (no se recopilan) |
| ¿Ofreces una forma de que los usuarios soliciten la eliminación de sus datos? | Sí: Ajustes > Eliminar todos mis datos (borrado local inmediato) |

Notas para el formulario:
- **Compras**: Google Play Billing es gestionado por Google; no se declara como recopilación de la app.
- **Exportar / Compartir reporte**: lo inicia el usuario y elige el destino → no cuenta como recopilación ni como compartir (excepción de Google para transferencias iniciadas por el usuario).
- Verifica antes de enviar que el AAB final **no** incluya INTERNET ni SDK de analítica/crash:
  `aapt2 dump permissions build/app/outputs/apk/release/app-release.apk`
- Si en la fase 2 se agrega sincronización o Crashlytics, la declaración cambia a: Salud y fitness > Información de salud (recopilada, cifrada en tránsito, eliminable, no compartida), Identificadores del dispositivo, etc.

## Otras declaraciones de Play Console

- **Apps de salud** (Contenido de la app > Apps de salud): marcar "Salud mental y bienestar emocional". Declarar que no es dispositivo médico.
- **Público objetivo**: 18+ (no dirigida a niños).
- **Anuncios**: No contiene anuncios.
- **Clasificación de contenido**: cuestionario IARC; mencionar referencias a autolesión solo en contexto de ayuda.
- **Política de privacidad**: URL pública con el texto de `assets/legal/politica_privacidad.md` (completar razón social, RUC, correo).
- **Eliminación de cuenta/datos**: no hay cuentas; indicar el borrado dentro de la app.
