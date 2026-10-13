import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// google-services.json lo genera `flutterfire configure` y no se sube a git (RNF-04).
// Sin él la app compila, pero Firebase no se inicializa.
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Firma del APK final (RNF-25): android/key.properties y la llave .jks no se
// suben a git (RNF-04). Plantilla: android/key.properties.example.
val propiedadesFirma = Properties().apply {
    val archivo = rootProject.file("key.properties")
    if (archivo.exists()) archivo.inputStream().use { load(it) }
}
val hayFirmaPropia = propiedadesFirma.getProperty("storeFile") != null

android {
    namespace = "gt.umg.agroclima_jalapa"
    // permission_handler exige compilar contra Android 37; no cambia los teléfonos soportados (minSdk).
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications necesita desugaring de java.time.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "gt.umg.agroclima_jalapa"
        // Android 8.0 o superior (CLAUDE.md §2).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hayFirmaPropia) {
            create("propia") {
                storeFile = rootProject.file(propiedadesFirma.getProperty("storeFile"))
                storePassword = propiedadesFirma.getProperty("storePassword")
                keyAlias = propiedadesFirma.getProperty("keyAlias")
                keyPassword = propiedadesFirma.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Sin key.properties sale con la firma de prueba: sirve para probar,
            // no para entregar (no se podría actualizar con la llave real).
            signingConfig = if (hayFirmaPropia) {
                signingConfigs.getByName("propia")
            } else {
                logger.warn("AVISO: falta android/key.properties; el APK de release usa la firma de prueba.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}

flutter {
    source = "../.."
}
