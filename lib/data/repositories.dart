import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';
import 'models.dart';
import 'secure_store.dart';

class MoodRepository {
  final SecureStore store;
  MoodRepository(this.store);

  Future<void> add(MoodEntry e) => store.moods.put(e.id, e.toMap());

  List<MoodEntry> all() {
    final list = store.moods.values
        .map((v) => MoodEntry.fromMap(SecureStore.asMap(v)))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  MoodEntry? latest() {
    final l = all();
    return l.isEmpty ? null : l.first;
  }
}

class SessionRepository {
  final SecureStore store;
  SessionRepository(this.store);

  Future<void> add(SessionRecord s) => store.sessions.put(s.id, s.toMap());

  List<SessionRecord> all() => store.sessions.values
      .map((v) => SessionRecord.fromMap(SecureStore.asMap(v)))
      .toList()
    ..sort((a, b) => b.at.compareTo(a.at));
}

/// Preferencias, consentimiento, PIN y estado de suscripción.
class SettingsRepository {
  final SecureStore store;
  SettingsRepository(this.store);

  T? _get<T>(String k) => store.settings.get(k) as T?;
  Future<void> _set(String k, Object? v) => store.settings.put(k, v);

  bool get introSeen => _get<bool>('introSeen') ?? false;
  Future<void> setIntroSeen() => _set('introSeen', true);

  bool get profileSetupDone => _get<bool>('profileSetupDone') ?? false;
  Future<void> setProfileSetupDone() => _set('profileSetupDone', true);

  ConsentRecord? get consent {
    final raw = store.settings.get('consent');
    return raw == null ? null : ConsentRecord.fromMap(SecureStore.asMap(raw));
  }

  Future<void> saveConsent(ConsentRecord c) => _set('consent', c.toMap());

  List<Problem> get concerns => (_get<List>('concerns') ?? const [])
      .map((n) => Problem.values.firstWhere((p) => p.name == n,
          orElse: () => Problem.anticipatoria))
      .toList();
  Future<void> setConcerns(List<Problem> p) =>
      _set('concerns', p.map((e) => e.name).toList());

  UserContext get lastContext => UserContext.values.firstWhere(
      (c) => c.name == _get<String>('lastContext'),
      orElse: () => UserContext.receso);
  Future<void> setLastContext(UserContext c) => _set('lastContext', c.name);

  // Bloqueo
  bool get lockEnabled => _get<bool>('lockEnabled') ?? false;
  bool get biometricEnabled => _get<bool>('biometricEnabled') ?? false;
  String? get pinHash => _get<String>('pinHash');
  String? get pinSalt => _get<String>('pinSalt');
  Future<void> setLock({
    required bool enabled,
    String? pinHash,
    String? pinSalt,
    bool? biometric,
  }) async {
    await _set('lockEnabled', enabled);
    if (!enabled) {
      await store.settings.delete('pinHash');
      await store.settings.delete('pinSalt');
      await _set('biometricEnabled', false);
      return;
    }
    if (pinHash != null) await _set('pinHash', pinHash);
    if (pinSalt != null) await _set('pinSalt', pinSalt);
    if (biometric != null) await _set('biometricEnabled', biometric);
  }

  // Crisis: bloquea ejercicios hasta un nuevo registro fuera de riesgo.
  bool get crisisActive => _get<bool>('crisisActive') ?? false;
  Future<void> setCrisisActive(bool v) => _set('crisisActive', v);

  // Suscripción (caché local; Google Play es la fuente de verdad)
  bool get premiumActive => _get<bool>('premiumActive') ?? false;
  bool get demoPremium => _get<bool>('demoPremium') ?? false;
  Future<void> setPremium(bool v) async {
    await _set('premiumActive', v);
    await _set('premiumCheckedAt', DateTime.now().toIso8601String());
  }

  Future<void> setDemoPremium(bool v) => _set('demoPremium', v);
}

class IdentityRepository {
  final SecureStore store;
  IdentityRepository(this.store);

  IdentityProfile get profile {
    final raw = store.identity.get('profile');
    if (raw != null) return IdentityProfile.fromMap(SecureStore.asMap(raw));
    final p = IdentityProfile(pseudoId: SecureStore.randomId());
    store.identity.put('profile', p.toMap());
    return p;
  }

  Future<void> save(IdentityProfile p) => store.identity.put('profile', p.toMap());
}

/// Derecho de acceso / portabilidad: exporta TODO en JSON legible.
class ExportService {
  final MoodRepository moods;
  final SessionRepository sessions;
  final SettingsRepository settings;
  final IdentityRepository identity;

  ExportService(this.moods, this.sessions, this.settings, this.identity);

  Map<String, dynamic> buildExport() => {
        'app': AppConstants.appName,
        'exportedAt': DateTime.now().toIso8601String(),
        'formatVersion': 1,
        'identity': identity.profile.toMap(),
        'consent': settings.consent?.toMap(),
        'preferences': {
          'concerns': settings.concerns.map((e) => e.name).toList(),
          'lockEnabled': settings.lockEnabled,
        },
        'moods': moods.all().map((e) => e.toMap()).toList(),
        'sessions': sessions.all().map((e) => e.toMap()).toList(),
      };

  Future<File> writeExportFile() async {
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${dir.path}/samai_mis_datos_$stamp.json');
    const encoder = JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(buildExport()));
    return file;
  }
}
