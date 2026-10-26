import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/constants.dart';
import '../data/models.dart';
import '../data/repositories.dart';
import '../data/secure_store.dart';
import '../domain/progress.dart';
import '../domain/risk_detector.dart';
import '../services/lock_service.dart';

/// Estado global de la app (Provider + ChangeNotifier).
class AppState extends ChangeNotifier with WidgetsBindingObserver {
  AppState(this.store)
      : moods = MoodRepository(store),
        sessions = SessionRepository(store),
        settings = SettingsRepository(store),
        identityRepo = IdentityRepository(store) {
    exporter = ExportService(moods, sessions, settings, identityRepo);
    locked = settings.lockEnabled;
    WidgetsBinding.instance.addObserver(this);
  }

  final SecureStore store;
  final MoodRepository moods;
  final SessionRepository sessions;
  final SettingsRepository settings;
  final IdentityRepository identityRepo;
  late final ExportService exporter;
  final LockService lock = LockService();

  bool locked = false;
  DateTime? _pausedAt;

  // ------------------------------------------------------------------ flujo
  bool get introSeen => settings.introSeen;
  bool get hasValidConsent {
    final c = settings.consent;
    return c != null && c.isValid && c.version == AppConstants.consentVersion;
  }

  bool get profileSetupDone => settings.profileSetupDone;
  IdentityProfile get identity => identityRepo.profile;

  Future<void> markIntroSeen() async {
    await settings.setIntroSeen();
    notifyListeners();
  }

  Future<void> acceptConsent(ConsentRecord c) async {
    await settings.saveConsent(c);
    notifyListeners();
  }

  Future<void> completeProfileSetup({
    required List<Problem> concerns,
    String? nickname,
    String? emergencyName,
    String? emergencyPhone,
  }) async {
    await settings.setConcerns(concerns);
    await identityRepo.save(identity.copyWith(
      nickname: nickname,
      emergencyName: emergencyName,
      emergencyPhone: emergencyPhone,
    ));
    await settings.setProfileSetupDone();
    notifyListeners();
  }

  Future<void> updateIdentity(IdentityProfile p) async {
    await identityRepo.save(p);
    notifyListeners();
  }

  // -------------------------------------------------------------- premium
  bool get isPremium => settings.premiumActive || settings.demoPremium;

  Future<void> setPremium(bool v) async {
    if (settings.premiumActive == v) return;
    await settings.setPremium(v);
    notifyListeners();
  }

  Future<void> setDemoPremium(bool v) async {
    if (!kDebugMode) return; // solo en compilaciones de prueba
    await settings.setDemoPremium(v);
    notifyListeners();
  }

  // ----------------------------------------------------------------- ánimo
  bool get crisisActive => settings.crisisActive;

  /// Guarda el registro y evalúa riesgo. Si hay riesgo, se activa el modo
  /// crisis (los ejercicios quedan bloqueados hasta un nuevo registro sin
  /// señales de riesgo).
  Future<RiskLevel> addMood({
    required int anxiety,
    required Emotion emotion,
    String? note,
    UserContext? context,
  }) async {
    final entry = MoodEntry(
      id: SecureStore.randomId(),
      pseudoId: identity.pseudoId,
      at: DateTime.now(),
      anxiety: anxiety,
      emotion: emotion,
      note: (note?.trim().isEmpty ?? true) ? null : note!.trim(),
      context: context,
    );
    await moods.add(entry);
    final risk = RiskDetector.evaluate(anxiety: anxiety, text: note);
    await settings.setCrisisActive(risk != RiskLevel.none);
    notifyListeners();
    return risk;
  }

  MoodEntry? get todayMood {
    final m = moods.latest();
    if (m == null) return null;
    final now = DateTime.now();
    return (m.at.year == now.year && m.at.month == now.month && m.at.day == now.day)
        ? m
        : null;
  }

  // -------------------------------------------------------------- sesiones
  Future<void> recordSession({
    required String exerciseId,
    required String title,
    required Problem problem,
    required int plannedSeconds,
    required bool completed,
  }) async {
    await sessions.add(SessionRecord(
      id: SecureStore.randomId(),
      pseudoId: identity.pseudoId,
      at: DateTime.now(),
      exerciseId: exerciseId,
      title: title,
      problem: problem,
      plannedSeconds: plannedSeconds,
      completed: completed,
    ));
    notifyListeners();
  }

  ProgressReport progress() => ProgressCalculator.build(
        moods: moods.all(),
        sessions: sessions.all(),
        now: DateTime.now(),
      );

  Future<void> setLastContext(UserContext c) async {
    await settings.setLastContext(c);
    notifyListeners();
  }

  // ----------------------------------------------------------------- bloqueo
  Future<void> enableLock(String pin, {required bool biometric}) async {
    final salt = LockService.newSalt();
    await settings.setLock(
      enabled: true,
      pinHash: LockService.hashPin(pin, salt),
      pinSalt: salt,
      biometric: biometric,
    );
    notifyListeners();
  }

  Future<void> disableLock() async {
    await settings.setLock(enabled: false);
    notifyListeners();
  }

  Future<void> setBiometric(bool v) async {
    await settings.setLock(enabled: true, biometric: v);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final salt = settings.pinSalt;
    final hash = settings.pinHash;
    if (salt == null || hash == null) return false;
    return LockService.hashPin(pin, salt) == hash;
  }

  void unlock() {
    locked = false;
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (s == AppLifecycleState.resumed) {
      final p = _pausedAt;
      if (settings.lockEnabled &&
          p != null &&
          DateTime.now().difference(p) > AppConstants.relockAfter) {
        locked = true;
        notifyListeners();
      }
      _pausedAt = null;
    }
  }

  // ----------------------------------------------------- derechos ARCO
  /// Elimina TODO (cancelación + revocación del consentimiento).
  Future<void> deleteAllData() async {
    await store.wipeAll();
    locked = false;
    notifyListeners();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
