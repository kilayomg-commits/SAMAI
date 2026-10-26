import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Almacenamiento local cifrado.
///
/// - Cada caja Hive se cifra con AES-256 (HiveAesCipher).
/// - Las llaves de 256 bits se generan en el dispositivo y se guardan en
///   flutter_secure_storage, respaldado por Android Keystore.
/// - Identidad y datos clínicos usan cajas Y llaves distintas (seudonimización).
/// - android:allowBackup="false": nada se copia a la nube de Google.
class SecureStore {
  static const _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _identityBox = 'identity';
  static const _moodBox = 'moods';
  static const _sessionBox = 'sessions';
  static const _settingsBox = 'settings';

  late Box identity; // apodo, contacto de emergencia (llave A)
  late Box moods; // registros de ánimo (llave B)
  late Box sessions; // sesiones de audio (llave B)
  late Box settings; // consentimiento, preferencias, PIN (llave C)

  Future<HiveAesCipher> _cipher(String keyName) async {
    var encoded = await _secure.read(key: keyName);
    if (encoded == null) {
      encoded = base64UrlEncode(Hive.generateSecureKey());
      await _secure.write(key: keyName, value: encoded);
    }
    return HiveAesCipher(base64Url.decode(encoded));
  }

  Future<void> init() async {
    await Hive.initFlutter('samai');
    await _open();
  }

  Future<void> _open() async {
    final identityKey = await _cipher('k_identity');
    final clinicalKey = await _cipher('k_clinical');
    final settingsKey = await _cipher('k_settings');
    identity = await Hive.openBox(_identityBox, encryptionCipher: identityKey);
    moods = await Hive.openBox(_moodBox, encryptionCipher: clinicalKey);
    sessions = await Hive.openBox(_sessionBox, encryptionCipher: clinicalKey);
    settings = await Hive.openBox(_settingsBox, encryptionCipher: settingsKey);
  }

  /// Borrado total e irreversible: cajas + llaves.
  Future<void> wipeAll() async {
    await identity.deleteFromDisk();
    await moods.deleteFromDisk();
    await sessions.deleteFromDisk();
    await settings.deleteFromDisk();
    await _secure.deleteAll();
    await _open(); // deja la app en estado limpio, con llaves nuevas
  }

  static String randomId([int bytes = 16]) {
    final r = Random.secure();
    return List.generate(bytes, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Map<String, dynamic> asMap(dynamic v) =>
      Map<String, dynamic>.from(v as Map);
}
