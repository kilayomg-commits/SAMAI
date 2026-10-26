import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../domain/risk_detector.dart';
import '../../state/app_state.dart';
import 'mood_screen.dart';

/// Protocolo de ayuda. Se muestra cuando la ansiedad es muy alta o se detectan
/// palabras de riesgo. No ofrece ejercicios: solo contacto humano.
class CrisisScreen extends StatelessWidget {
  final RiskLevel level;
  const CrisisScreen({super.key, this.level = RiskLevel.high});

  static Future<void> open(BuildContext context,
          {RiskLevel level = RiskLevel.high}) =>
      Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true, builder: (_) => CrisisScreen(level: level)));

  Future<void> _call(String number) =>
      launchUrl(Uri(scheme: 'tel', path: number));

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final contact = s.identity;
    final critical = level == RiskLevel.critical;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8F6),
        title: const Text('Estamos contigo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              critical
                  ? 'Lo que escribiste nos importa mucho. Si estás pensando en '
                      'hacerte daño, no tienes que pasar por esto a solas. Habla '
                      'ahora con una persona preparada para ayudarte.'
                  : 'Parece que estás sintiendo un malestar muy intenso. En este '
                      'momento lo mejor no es un ejercicio, sino hablar con alguien.',
              style: const TextStyle(fontSize: 17, height: 1.4),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: SamaiTheme.crisis,
                minimumSize: const Size.fromHeight(64),
              ),
              onPressed: () => _call(CrisisLines.minsa),
              icon: const Icon(Icons.call),
              label: const Text('Llamar a la Línea 113\n(luego marca la opción 5)',
                  textAlign: TextAlign.center),
            ),
            const SizedBox(height: 6),
            const Text(
              'Línea 113 Salud del MINSA, opción 5: orientación en salud mental '
              'gratuita, las 24 horas, desde cualquier celular o fijo.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                  Uri.parse('https://wa.me/${CrisisLines.minsaWhatsapp}'),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Escribir a Infosalud por WhatsApp'),
            ),
            if (contact.emergencyPhone != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _call(contact.emergencyPhone!),
                icon: const Icon(Icons.favorite_border),
                label: Text(
                    'Llamar a ${contact.emergencyName ?? 'mi contacto de confianza'}'),
              ),
            ],
            const SizedBox(height: 24),
            const Text('Si estás en peligro inmediato',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text(
                'Ve a la emergencia del hospital más cercano o llama a:'),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ActionChip(
                  avatar: const Icon(Icons.local_hospital, size: 18),
                  label: const Text('SAMU 106'),
                  onPressed: () => _call(CrisisLines.samu)),
              ActionChip(
                  avatar: const Icon(Icons.local_police, size: 18),
                  label: const Text('Policía 105'),
                  onPressed: () => _call(CrisisLines.policia)),
              ActionChip(
                  avatar: const Icon(Icons.fire_truck, size: 18),
                  label: const Text('Bomberos 116'),
                  onPressed: () => _call(CrisisLines.bomberos)),
            ]),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Mientras tanto: si puedes, aléjate de cualquier objeto con el '
                  'que podrías hacerte daño y busca estar cerca de alguien. '
                  'Respira despacio; esta intensidad puede bajar.',
                ),
              ),
            ),
            if (s.crisisActive) ...[
              const SizedBox(height: 16),
              const Text(
                'Los ejercicios quedarán en pausa hasta que registres de nuevo cómo '
                'te sientes y el malestar haya bajado.',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MoodScreen())),
                child: const Text('Registrar cómo me siento ahora'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
