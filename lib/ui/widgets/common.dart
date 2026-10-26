import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../screens/crisis_screen.dart';
import '../screens/subscription_screen.dart';

/// Aviso permanente: SAMAI no es tratamiento médico. Un toque abre la ayuda.
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDE6DA),
      child: InkWell(
        onTap: () => CrisisScreen.open(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SAMAI es apoyo al bienestar, no es tratamiento médico ni '
                  'diagnóstico. ¿Necesitas ayuda ahora? Toca aquí · Línea 113, opción 5.',
                  style: TextStyle(fontSize: 11.5, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reemplaza los ejercicios mientras el modo crisis está activo.
class CrisisBlockCard extends StatelessWidget {
  const CrisisBlockCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFCE8E6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.favorite, color: SamaiTheme.crisis),
              SizedBox(width: 8),
              Expanded(
                child: Text('Ahora lo más importante es tu seguridad',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 8),
            const Text(
                'Pausamos los ejercicios porque tu último registro mostró un '
                'malestar muy alto. Habla con alguien: la Línea 113, opción 5, es '
                'gratuita y atiende las 24 horas.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: SamaiTheme.crisis),
              onPressed: () => CrisisScreen.open(context),
              icon: const Icon(Icons.call),
              label: const Text('Ver opciones de ayuda'),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumLock extends StatelessWidget {
  const PremiumLock({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3D6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.lock, size: 13),
          SizedBox(width: 4),
          Text('Premium', style: TextStyle(fontSize: 12)),
        ]),
      );
}

void openSubscription(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute(builder: (_) => const SubscriptionScreen()));

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium),
      );
}
