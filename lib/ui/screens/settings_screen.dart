import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models.dart';
import '../../services/lock_service.dart';
import '../../state/app_state.dart';
import '../widgets/common.dart';
import 'consent_screen.dart';
import 'crisis_screen.dart';

/// Ajustes + ajustes de privacidad (derechos ARCO y portabilidad).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final consent = s.settings.consent;
    final df = DateFormat('dd/MM/yyyy HH:mm', 'es');

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall),
        ),
        const _Header('Suscripción'),
        ListTile(
          leading: const Icon(Icons.auto_awesome),
          title: Text(s.isPremium ? 'Premium activo' : 'Plan gratuito'),
          subtitle: const Text('Ver planes, restaurar o cancelar'),
          onTap: () => openSubscription(context),
        ),
        const _Header('Seguridad'),
        SwitchListTile(
          secondary: const Icon(Icons.lock_outline),
          title: const Text('Bloquear con PIN'),
          subtitle: const Text('Se pide al abrir SAMAI'),
          value: s.settings.lockEnabled,
          onChanged: (v) => v ? _setupPin(context) : s.disableLock(),
        ),
        if (s.settings.lockEnabled)
          FutureBuilder<bool>(
            future: s.lock.canUseBiometrics(),
            builder: (_, snap) => snap.data == true
                ? SwitchListTile(
                    secondary: const Icon(Icons.fingerprint),
                    title: const Text('Desbloquear con huella o rostro'),
                    value: s.settings.biometricEnabled,
                    onChanged: s.setBiometric,
                  )
                : const SizedBox.shrink(),
          ),
        const _Header('Ayuda'),
        ListTile(
          leading: const Icon(Icons.support_agent),
          title: const Text('Necesito ayuda ahora'),
          subtitle: const Text('Línea 113, opción 5 · emergencias'),
          onTap: () => CrisisScreen.open(context),
        ),
        ListTile(
          leading: const Icon(Icons.contact_phone_outlined),
          title: const Text('Contacto de confianza'),
          subtitle: Text(s.identity.emergencyName ?? 'No configurado'),
          onTap: () => _editContact(context),
        ),
        ListTile(
          leading: const Icon(Icons.checklist),
          title: const Text('Temas que quiero trabajar'),
          subtitle: Text(s.settings.concerns.map((p) => p.label).join(', ')),
          onTap: () => _editConcerns(context),
        ),
        const _Header('Privacidad y tus datos'),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined),
          title: const Text('Consentimiento otorgado'),
          subtitle: Text(consent == null
              ? '—'
              : 'Versión ${consent.version} · ${df.format(consent.acceptedAt)}'),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Política de privacidad'),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Exportar mis datos'),
          subtitle: const Text('Archivo JSON con todos tus registros'),
          onTap: () => _export(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Eliminar todos mis datos',
              style: TextStyle(color: Colors.red)),
          subtitle: const Text(
              'Borra registros, ajustes y llaves de cifrado. También retira tu consentimiento.'),
          onTap: () => _delete(context),
        ),
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'SAMAI guarda tus datos solo en este celular, cifrados con AES-256. '
            'No usa publicidad, analítica ni servidores propios. Es una '
            'herramienta de bienestar y no reemplaza la atención profesional.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  Future<void> _setupPin(BuildContext context) async {
    final s = context.read<AppState>();
    final pin = await showDialog<String>(
      context: context,
      builder: (_) => const _PinDialog(),
    );
    if (pin == null) return;
    final bio = await s.lock.canUseBiometrics();
    await s.enableLock(pin, biometric: bio);
  }

  Future<void> _export(BuildContext context) async {
    final s = context.read<AppState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Exportar mis datos'),
        content: const Text(
            'Se creará un archivo SIN cifrar con todos tus registros, para que '
            'lo guardes o lo envíes a donde tú elijas. Cuida dónde lo compartes.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Exportar')),
        ],
      ),
    );
    if (ok != true) return;
    final file = await s.exporter.writeExportFile();
    await Share.shareXFiles([XFile(file.path, mimeType: 'application/json')],
        subject: 'Mis datos de SAMAI');
  }

  Future<void> _delete(BuildContext context) async {
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setD) => AlertDialog(
          title: const Text('¿Eliminar todo?'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
                'Esta acción es permanente. Se borrarán tus registros de ánimo, '
                'sesiones, contacto de confianza y ajustes. Si tienes Premium, '
                'cancélalo aparte en Google Play.\n\nEscribe ELIMINAR para confirmar.'),
            TextField(controller: ctrl, onChanged: (_) => setD(() {})),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: ctrl.text.trim().toUpperCase() == 'ELIMINAR'
                  ? () => Navigator.pop(d, true)
                  : null,
              child: const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (ok != true) return;
    nav.popUntil((r) => r.isFirst);
    await s.deleteAllData();
  }

  Future<void> _editContact(BuildContext context) async {
    final s = context.read<AppState>();
    final id = s.identity;
    final name = TextEditingController(text: id.emergencyName);
    final phone = TextEditingController(text: id.emergencyPhone);
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Contacto de confianza'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre')),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular')),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Guardar')),
        ],
      ),
    );
    if (ok == true) {
      String? clean(String t) => t.trim().isEmpty ? null : t.trim();
      await s.updateIdentity(IdentityProfile(
        pseudoId: id.pseudoId,
        nickname: id.nickname,
        emergencyName: clean(name.text),
        emergencyPhone: clean(phone.text),
      ));
    }
    name.dispose();
    phone.dispose();
  }

  Future<void> _editConcerns(BuildContext context) async {
    final s = context.read<AppState>();
    final selected = s.settings.concerns.toSet();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setD) => AlertDialog(
          title: const Text('Temas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Problem.values
                .map((p) => CheckboxListTile(
                      value: selected.contains(p),
                      title: Text(p.label),
                      onChanged: (v) => setD(() =>
                          v == true ? selected.add(p) : selected.remove(p)),
                    ))
                .toList(),
          ),
          actions: [
            FilledButton(
              onPressed:
                  selected.isEmpty ? null : () => Navigator.pop(d, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true) {
      await s.settings.setConcerns(selected.toList());
      await s.setLastContext(s.settings.lastContext); // notifica cambios
    }
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                letterSpacing: 1,
                color: Theme.of(context).colorScheme.primary)),
      );
}

class _PinDialog extends StatefulWidget {
  const _PinDialog();
  @override
  State<_PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<_PinDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _err;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Crea un PIN'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _a,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(labelText: 'PIN (4 a 6 dígitos)'),
          ),
          TextField(
            controller: _b,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(labelText: 'Repite el PIN', errorText: _err),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!LockService.isValidPin(_a.text)) {
                setState(() => _err = 'Usa de 4 a 6 números');
              } else if (_a.text != _b.text) {
                setState(() => _err = 'Los PIN no coinciden');
              } else {
                Navigator.pop(context, _a.text);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      );
}
