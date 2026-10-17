import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release fixa, como no movva-app: com a chave de debug cada
// máquina assinaria diferente e o Android recusaria atualizar o app
// ("pacote em conflito"). A keystore é versionada (repo privado) em
// android/key.properties + release.jks; POKEDEX_ANDROID_KEY_PROPERTIES troca o
// caminho. `storeFile` é relativo à pasta do key.properties.
val keyPropertiesFile = System.getenv("POKEDEX_ANDROID_KEY_PROPERTIES")?.let { file(it) }
    ?: rootProject.file("key.properties")
val keyProperties = Properties().apply {
    if (keyPropertiesFile.exists()) FileInputStream(keyPropertiesFile).use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

android {
    namespace = "com.adrianbueno.pokedex"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.adrianbueno.pokedex"
        // Flutter 3.47 exige 24; drift/sqlite3 pedem 21+, então 24 atende os dois.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
                storePassword = keyProperties.getProperty("storePassword")
                storeFile = keyPropertiesFile.parentFile.resolve(keyProperties.getProperty("storeFile"))
            }
        }
    }

    buildTypes {
        release {
            // Sem a keystore o release cai na chave de debug: esse APK não
            // atualiza os aparelhos.
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("[signing] key.properties não encontrado em $keyPropertiesFile: release assinado com a chave de DEBUG")
                signingConfigs.getByName("debug")
            }
            // O plugin do ML Kit referencia os reconhecedores de outros alfabetos, que não vão no app.
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
