import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models.dart';
import '../../state/app_state.dart';

/// Personalización mínima (después del consentimiento). Todo es opcional
/// salvo elegir al menos un tema.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});
  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _selected = <Problem>{};
  final _nick = TextEditingController();
  final _eName = TextEditingController();
  final _ePhone = TextEditingController();

  @override
  void dispose() {
    _nick.dispose();
    _eName.dispose();
    _ePhone.dispose();
    super.dispose();
  }

  String? _clean(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personaliza SAMAI')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('¿Con qué te gustaría trabajar?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Elige uno o más. Puedes cambiarlo después.'),
            const SizedBox(height: 8),
            ...Problem.values.map((p) => CheckboxListTile(
                  value: _selected.contains(p),
                  onChanged: (v) => setState(
                      () => v == true ? _selected.add(p) : _selected.remove(p)),
                  title: Text(p.label),
                  subtitle: Text(p.hint),
                )),
            const Divider(height: 32),
            TextField(
              controller: _nick,
              decoration: const InputDecoration(
                labelText: '¿Cómo quieres que te llame? (opcional)',
                hintText: 'Un apodo basta',
              ),
            ),
            const SizedBox(height: 20),
            Text('Contacto de confianza (opcional)',
                style: Theme.of(context).textTheme.titleMedium),
            const Text(
                'Lo mostraremos solo en la pantalla de ayuda para que puedas '
                'llamarle rápido. Nunca le escribimos ni lo compartimos.',
                style: TextStyle(fontSize: 13)),
            TextField(
              controller: _eName,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: _ePhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Celular'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _selected.isEmpty
                  ? null
                  : () => context.read<AppState>().completeProfileSetup(
                        concerns: _selected.toList(),
                        nickname: _clean(_nick),
                        emergencyName: _clean(_eName),
                        emergencyPhone: _clean(_ePhone),
                      ),
              child: const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}
