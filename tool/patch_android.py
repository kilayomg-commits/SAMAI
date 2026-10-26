"""Ajusta el android/app/build.gradle.kts que genera `flutter create`:
- minSdk = 29 (Android 10+)
- firma de release con android/key.properties (si existe)
Se ejecuta una vez después de `flutter create`. Es idempotente."""
import pathlib, re, sys

p = pathlib.Path(__file__).resolve().parent.parent / "android/app/build.gradle.kts"
s = p.read_text(encoding="utf-8")

s = re.sub(r"minSdk\s*=\s*[^\n]+", "minSdk = 29", s, count=1)

if "keystoreProperties" not in s:
    s = ("import java.io.FileInputStream\nimport java.util.Properties\n\n" + s)
    s = s.replace("android {", '''val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {''', 1)
    s = s.replace("    buildTypes {", '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {''', 1)
    s = re.sub(r'(release\s*\{[^}]*?)signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)',
               r'\1signingConfig = if (keystorePropertiesFile.exists()) signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
               s, count=1, flags=re.S)

p.write_text(s, encoding="utf-8")
print("build.gradle.kts ajustado:", p)
