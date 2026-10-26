import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';

/// Consentimiento informado: previo, libre, expreso, inequívoco e informado
/// (Ley 29733 y su Reglamento, D.S. 016-2024-JUS). Se pide ANTES del primer
/// registro y se guarda constancia (versión + fecha/hora).
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});
  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _adult = false;
  bool _policy = false;
  bool _sensitive = false;

  @override
  Widget build(BuildContext context) {
    final all = _adult && _policy && _sensitive;
    return Scaffold(
      appBar: AppBar(title: const Text('Tu privacidad')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            const Text(
              'Antes de empezar, queremos que sepas exactamente qué hacemos con tu '
              'información.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            const _Point(Icons.phone_android,
                'Tus registros se guardan solo en este celular, cifrados. No tenemos servidores que los reciban.'),
            const _Point(Icons.block,
                'No vendemos ni compartimos tus datos. No usamos publicidad ni rastreadores.'),
            const _Point(Icons.badge_outlined,
                'Tus registros de ánimo no llevan tu nombre: se guardan con un código aleatorio, separados de tus datos de contacto.'),
            const _Point(Icons.download,
                'Puedes exportar o eliminar todos tus datos cuando quieras, desde Ajustes.'),
            const _Point(Icons.medical_information_outlined,
                'SAMAI no diagnostica ni reemplaza a un profesional de salud mental.'),
            TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen())),
              icon: const Icon(Icons.article_outlined),
              label: const Text('Leer la política de privacidad completa'),
            ),
            const Divider(height: 24),
            CheckboxListTile(
              value: _adult,
              onChanged: (v) => setState(() => _adult = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Confirmo que tengo 18 años o más.'),
            ),
            CheckboxListTile(
              value: _policy,
              onChanged: (v) => setState(() => _policy = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                  'He leído y acepto la Política de Privacidad y los Términos de uso.'),
            ),
            CheckboxListTile(
              value: _sensitive,
              onChanged: (v) => setState(() => _sensitive = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(
                  'Autorizo de forma expresa el tratamiento de mis datos de salud '
                  'emocional (nivel de ansiedad, emociones y notas), que son datos '
                  'sensibles, solo para que SAMAI me muestre ejercicios y mi progreso.'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: all
                  ? () => context.read<AppState>().acceptConsent(ConsentRecord(
                        version: AppConstants.consentVersion,
                        acceptedAt: DateTime.now(),
                        adultConfirmed: _adult,
                        privacyPolicyAccepted: _policy,
                        sensitiveDataConsent: _sensitive,
                      ))
                  : null,
              child: const Text('Acepto y continúo'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Si no aceptas, no podremos guardar tus registros. Puedes retirar tu '
              'consentimiento en cualquier momento desde Ajustes > Privacidad.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Point(this.icon, this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ]),
      );
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Política de privacidad')),
        body: FutureBuilder<String>(
          future: rootBundle.loadString('assets/legal/politica_privacidad.md'),
          builder: (_, snap) => snap.hasData
              ? SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: SelectableText(snap.data!,
                      style: const TextStyle(height: 1.45)),
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      );
}
