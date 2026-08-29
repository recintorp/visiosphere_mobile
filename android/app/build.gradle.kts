import java.util.Properties
import java.io.FileInputStream

// Release signing credentials. Kept OUT of version control (android/.gitignore)
// so the keystore password never lands in a commit — build.gradle.kts is
// tracked, key.properties is not.
//
// Absent (a fresh clone, or CI without the secret) the release build falls back
// to debug signing below rather than failing outright, so `flutter build apk`
// still works for anyone who just wants to run the thing.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.visiosphere_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // ── BEFORE PUBLISHING TO GOOGLE PLAY, THIS MUST CHANGE ──────────────
        // Play REFUSES any package under com.example. Kept as-is for now on
        // purpose: internal test builds do not care what the package is called,
        // and renaming it breaks Firebase until the new package is registered.
        //
        // To rename, when you are actually ready to publish:
        //   1. Firebase console -> project "visiosphere-app" -> Project settings
        //      -> Add app -> Android -> package name "live.visiosphere.app"
        //      (reverse-DNS of visiosphere.live; leave the old app registered)
        //   2. Download the new google-services.json over android/app/
        //   3. Change the line below to "live.visiosphere.app"
        // Do those together — step 3 alone fails the build with
        // "No matching client found for package name".
        //
        // `namespace` above stays com.example.* either way: it only names the
        // generated R/BuildConfig classes and must match MainActivity.kt's
        // package. applicationId and namespace are allowed to differ, and
        // changing namespace would mean moving Kotlin sources for no gain.
        applicationId = "com.example.visiosphere_mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            // rootProject.file(), NOT file(). Inside the :app module, file()
            // resolves against android/app/, so "../upload-keystore.jks" landed
            // on android/upload-keystore.jks and the build failed with
            // "Keystore file ... not found". rootProject is android/, so a path
            // in key.properties is read relative to THAT — which is where
            // key.properties itself lives, so the two agree.
            // Absolute paths still work: rootProject.file() returns them as-is.
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Was `signingConfigs.getByName("debug")` — every release build was
            // signed with the debug key, which Play rejects and which anyone can
            // reproduce (it ships with the SDK).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}