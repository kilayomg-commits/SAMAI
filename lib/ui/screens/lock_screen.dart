import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';

/// Pantalla de bloqueo con teclado numérico propio (no usa TextField, así
/// funciona como capa superpuesta sobre cualquier pantalla).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});
  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  int _fails = 0;
  DateTime? _blockedUntil;
  String? _msg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    final s = context.read<AppState>();
    if (!s.settings.biometricEnabled) return;
    final ok = await s.lock.authenticateBiometric();
    if (ok && mounted) s.unlock();
  }

  void _tap(String d) {
    final until = _blockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      setState(() => _msg =
          'Demasiados intentos. Espera ${until.difference(DateTime.now()).inSeconds + 1} s.');
      return;
    }
    if (_pin.length >= 6) return;
    setState(() {
      _pin += d;
      _msg = null;
    });
  }

  void _submit() {
    final s = context.read<AppState>();
    if (s.verifyPin(_pin)) {
      s.unlock();
      return;
    }
    _fails++;
    setState(() {
      _pin = '';
      if (_fails >= 5) {
        _blockedUntil = DateTime.now().add(Duration(seconds: 30 * (_fails - 4)));
        _msg = 'PIN incorrecto. Espera un momento antes de reintentar.';
      } else {
        _msg = 'PIN incorrecto';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bio = context.read<AppState>().settings.biometricEnabled;
    Widget key(String label, {VoidCallback? onTap, Widget? child}) => SizedBox(
          width: 76,
          height: 76,
          child: TextButton(
            onPressed: onTap ?? () => _tap(label),
            style: TextButton.styleFrom(shape: const CircleBorder()),
            child: child ??
                Text(label, style: const TextStyle(fontSize: 26)),
          ),
        );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline,
                  size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              const Text('Ingresa tu PIN', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  6,
                  (i) => Container(
                    margin: const EdgeInsets.all(6),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _pin.length
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black12,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: _msg == null
                    ? null
                    : Text(_msg!, style: const TextStyle(color: Colors.red)),
              ),
              for (final row in const [
                ['1', '2', '3'],
                ['4', '5', '6'],
                ['7', '8', '9'],
              ])
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: row.map((d) => key(d)).toList()),
              Row(mainAxisSize: MainAxisSize.min, children: [
                key('bio',
                    onTap: bio ? _tryBiometric : () {},
                    child: bio ? const Icon(Icons.fingerprint, size: 30) : const SizedBox()),
                key('0'),
                key('del',
                    onTap: () => setState(() => _pin = _pin.isEmpty
                        ? _pin
                        : _pin.substring(0, _pin.length - 1)),
                    child: const Icon(Icons.backspace_outlined)),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: _pin.length >= 4 ? _submit : null,
                child: const Text('Desbloquear'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
