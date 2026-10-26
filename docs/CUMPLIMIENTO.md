# Matriz de cumplimiento — Ley N.° 29733 y Reglamento (D.S. N.° 016-2024-JUS)

> Referencia técnica, no asesoría legal. Validar con un abogado especialista antes de publicar.

| Requisito | Cómo lo cumple SAMAI | Dónde |
|---|---|---|
| Consentimiento previo, libre, expreso, informado e inequívoco | Pantalla obligatoria antes del primer registro, casillas sin marcar, constancia con versión y fecha | `consent_screen.dart`, `ConsentRecord` |
| Consentimiento expreso para datos sensibles (salud) | Casilla separada y específica para datos de salud emocional | `consent_screen.dart` |
| Información clara (deber de informar) | Resumen en lenguaje simple + política completa | `assets/legal/politica_privacidad.md` |
| Finalidad y proporcionalidad (minimización) | Sin nombre real, DNI, correo, ubicación ni contactos; campos de identidad opcionales | `models.dart` |
| Seguridad (medidas técnicas) | AES-256 en reposo, llaves en Keystore, sin INTERNET, sin backup en la nube, FLAG_SECURE, PIN con hash + sal, biometría | `secure_store.dart`, `AndroidManifest.xml`, `MainActivity.kt` |
| Seudonimización | `pseudoId` aleatorio en registros clínicos; identidad en caja y llave separadas | `secure_store.dart` |
| Derechos de acceso y portabilidad | Exportación JSON estructurada | Ajustes > Exportar mis datos |
| Cancelación / revocación | Borrado total (cajas + llaves) | Ajustes > Eliminar todos mis datos |
| Rectificación | Edición de contacto y temas | Ajustes |
| No transferencia a terceros | No hay SDK de terceros que reciban datos; sin publicidad ni analítica | `pubspec.yaml` |
| Menores de edad | Restringida a 18+ (abrir a 14–17 requiere revisión legal y consentimiento de padres/tutores según corresponda) | Consentimiento |
| Decisiones automatizadas | La detección de riesgo solo muestra información de ayuda; no limita derechos ni se comunica a nadie | `risk_detector.dart` |
| Banco de datos / Oficial de datos personales | En el MVP los datos no llegan al responsable. Si se activa sincronización (fase 2): inscribir el banco de datos ante la ANPD, designar Oficial de Datos Personales (tratamiento de datos sensibles) y hacer evaluación de impacto | `ARQUITECTURA.md` §8 |

## Seguridad clínica — checklist antes de publicar
- [ ] Psicólogo colegiado (CPsP) revisa guiones de audio y lista de palabras de riesgo.
- [ ] Verificar vigencia de Línea 113 opción 5, WhatsApp Infosalud, 106, 105, 116.
- [ ] Prueba manual: ansiedad 9 y 10, notas con y sin tildes → protocolo y ejercicios en pausa.
- [ ] El aviso "no es tratamiento médico" es visible en todas las pantallas principales.
