import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../data/secure_store.dart';

/// Bloqueo opcional de la app con PIN y/o biometría.
/// El PIN nunca se guarda en claro: se guarda sal + hash SHA-256 iterado,
/// dentro de una caja cifrada cuya llave vive en Android Keystore.
class LockService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canUseBiometrics() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Desbloquea SAMAI',
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } on PlatformException {
      return false;
    }
  }

  static String newSalt() => SecureStore.randomId();

  static String hashPin(String pin, String salt) {
    final saltBytes = utf8.encode(salt);
    var digest = sha256.convert(utf8.encode('$salt:$pin'));
    for (var i = 0; i < 20000; i++) {
      digest = sha256.convert([...digest.bytes, ...saltBytes]);
    }
    return digest.toString();
  }

  static bool isValidPin(String pin) => RegExp(r'^\d{4,6}$').hasMatch(pin);
}
