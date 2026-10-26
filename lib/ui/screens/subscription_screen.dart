import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../services/billing_service.dart';
import '../../state/app_state.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final billing = context.watch<BillingService>();

    return Scaffold(
      appBar: AppBar(title: const Text('SAMAI Premium')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (s.isPremium)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const ListTile(
                  leading: Icon(Icons.verified),
                  title: Text('Tienes Premium activo'),
                  subtitle: Text('Gracias por apoyar SAMAI.'),
                ),
              ),
            const _Row(Icons.library_music, 'Biblioteca completa',
                'Todos los ejercicios para ansiedad anticipatoria, estrés académico y laboral, insomnio y rumiación.'),
            const _Row(Icons.tune, 'Audios armados para ti',
                'Cada sesión se combina según tu problema, si estás trabajando, estudiando o en receso, y el tiempo que tienes.'),
            const _Row(Icons.summarize, 'Reportes semanales',
                'Emociones de la semana y un reporte que puedes compartir con tu psicólogo.'),
            const SizedBox(height: 8),
            const Text('Gratis seguirás teniendo: registro de ánimo, progreso básico y 3 audios.',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 24),
            Text('${billing.price} al mes',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium),
            const Text(
                'Prueba gratis por ${AppConstants.trialDays} días. Cancela cuando quieras.',
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            if (!s.isPremium)
              FilledButton(
                onPressed: billing.busy ? null : billing.buy,
                child: billing.busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Empezar prueba gratuita'),
              ),
            if (billing.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(billing.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: billing.busy ? null : billing.restore,
              child: const Text('Restaurar compra'),
            ),
            TextButton.icon(
              onPressed: billing.openManageSubscription,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Gestionar o cancelar en Google Play'),
            ),
            const SizedBox(height: 12),
            const Text(
              'El cobro lo realiza Google Play al terminar la prueba gratuita y se '
              'renueva cada mes hasta que canceles. Puedes cancelar en cualquier '
              'momento desde Google Play > Pagos y suscripciones; mantendrás '
              'Premium hasta el final del periodo pagado. SAMAI no recibe ni '
              'guarda datos de tu tarjeta.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (kDebugMode) ...[
              const Divider(height: 32),
              SwitchListTile(
                title: const Text('Modo demo Premium (solo debug)'),
                subtitle: const Text('Para probar el APK sin Google Play.'),
                value: s.settings.demoPremium,
                onChanged: s.setDemoPremium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _Row(this.icon, this.title, this.body);
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(body),
      );
}
