import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseSigningPropertiesFile = rootProject.file("key.properties")
val releaseSigningProperties = Properties()
val releaseSigningRequested =
    gradle.startParameter.taskNames.any { taskName ->
        taskName.contains("release", ignoreCase = true)
    }

if (releaseSigningPropertiesFile.exists()) {
    releaseSigningPropertiesFile.inputStream().use(releaseSigningProperties::load)
}

val requiredReleaseSigningProperties =
    listOf("storeFile", "storePassword", "keyAlias", "keyPassword")

if (releaseSigningRequested) {
    if (!releaseSigningPropertiesFile.exists()) {
        throw GradleException(
            "Release signing credentials are missing. " +
                "Create android/key.properties with storeFile, storePassword, " +
                "keyAlias, and keyPassword.",
        )
    }

    val missingProperties =
        requiredReleaseSigningProperties.filter { propertyName ->
            releaseSigningProperties.getProperty(propertyName).isNullOrBlank()
        }

    if (missingProperties.isNotEmpty()) {
        throw GradleException(
            "Release signing credentials are incomplete in android/key.properties. " +
                "Missing: ${missingProperties.joinToString()}.",
        )
    }

    val releaseKeystoreFile = file(releaseSigningProperties.getProperty("storeFile"))
    if (!releaseKeystoreFile.isFile) {
        throw GradleException(
            "Release signing keystore was not found at ${releaseKeystoreFile.absolutePath}.",
        )
    }
}

val hasCompleteReleaseSigningConfiguration =
    releaseSigningPropertiesFile.exists() &&
        requiredReleaseSigningProperties.all { propertyName ->
            !releaseSigningProperties.getProperty(propertyName).isNullOrBlank()
        }

android {
    namespace = "ma.raqmain.darjar"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "ma.raqmain.darjar"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasCompleteReleaseSigningConfiguration) {
            create("release") {
                storeFile = file(releaseSigningProperties.getProperty("storeFile"))
                storePassword = releaseSigningProperties.getProperty("storePassword")
                keyAlias = releaseSigningProperties.getProperty("keyAlias")
                keyPassword = releaseSigningProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasCompleteReleaseSigningConfiguration) {
                signingConfig = signingConfigs.getByName("release")
            }
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
