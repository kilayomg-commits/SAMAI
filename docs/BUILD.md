# Cómo compilar SAMAI (APK de prueba y AAB firmado)

## 0. Requisitos
- Flutter **3.29 o superior** (canal stable) → `flutter --version`
- Android Studio (SDK de Android 35+, Command-line Tools) y JDK 17
- `flutter doctor` sin errores en la sección Android

## 1. Completar el andamiaje de Android
El proyecto trae solo los archivos de Android que SAMAI personaliza (manifiesto, `MainActivity`, reglas de backup); `build.gradle.kts` lo genera Flutter y `tool/patch_android.py` le aplica minSdk 29 y la firma de release. El resto (Gradle wrapper, `settings.gradle.kts`, íconos, estilos) lo genera Flutter **sin sobrescribir** lo existente:

```bash
cd samai
flutter create --org pe.samai --project-name samai --platforms android .
rm test/widget_test.dart   # en Windows: del test\widget_test.dart (ejemplo que crea Flutter)
python tool/patch_android.py   # minSdk 29 + firma de release
flutter pub get
flutter test          # pruebas del dominio: riesgo, compositor, recomendador, progreso
```

Verifica que siga existiendo un solo `MainActivity.kt` en `android/app/src/main/kotlin/pe/samai/samai/` y que herede de `FlutterFragmentActivity`.

## 2. APK de prueba
```bash
# Con celular conectado (depuración USB activa)
flutter run

# APK instalable para compartir con testers (firmado con llave debug)
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
adb install build/app/outputs/flutter-apk/app-release.apk
```
En builds **debug**, Suscripción muestra el interruptor "Modo demo Premium" para probar todo sin Google Play. En release no aparece.

## 3. Llave de subida (una sola vez)
Windows (PowerShell):
```powershell
keytool -genkey -v -keystore $env:USERPROFILE\samai-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
macOS/Linux:
```bash
keytool -genkey -v -keystore ~/samai-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Copia `android/key.properties.example` → `android/key.properties` y completa claves y ruta. **Guarda el .jks y las claves en un lugar seguro**; no los subas a git (ya están en `.gitignore`).

## 4. AAB firmado para Play Store
```bash
flutter build appbundle --release
# → build/app/outputs/bundle/release/app-release.aab
```
Antes de cada versión sube `version:` en `pubspec.yaml` (ej. `1.0.1+2`; el número tras `+` es el versionCode).

Comprobar permisos del build final (no debe aparecer INTERNET):
```bash
flutter build apk --release
aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
```

## 5. Google Play Console
1. Crear la app → activar **Firma de apps de Play** → subir el AAB a **Prueba interna**.
2. Monetizar > Productos > **Suscripciones** → ID `samai_premium_mensual`:
   - Plan base: renovación automática mensual, precio **PEN 10.00**.
   - Oferta: **prueba gratuita de 7 días**, elegibilidad "nuevos clientes" (si cambias los días, actualiza `AppConstants.trialDays`).
3. Configuración > **Prueba de licencias**: agrega tu Gmail para comprar sin cargos reales.
4. Completa Contenido de la app (ver `DATA_SAFETY.md`): política de privacidad (URL pública), Seguridad de los datos, Apps de salud, público 18+, sin anuncios, clasificación de contenido.
5. Cuentas de desarrollador personales nuevas deben pasar una **prueba cerrada** con testers antes de producción (actualmente 12 testers durante 14 días; verifica el requisito vigente en Play Console).

## 6. Reemplazar los audios de prueba
`assets/audio/*.wav` son tonos de marcador de posición (1,6 s). Graba cada segmento con los guiones de `GUIONES_AUDIO.md`, respetando la duración indicada (`seconds` en `audio_catalog.dart`). Recomendado: voz cálida, español peruano neutro, mono 44,1 kHz, exportado a `.m4a` (AAC 64 kbps). Si cambias la extensión, actualiza `Segment.asset`.
