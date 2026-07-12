import java.util.Properties

plugins {

    id("com.android.application")

    // START: FlutterFire Configuration

    id("com.google.gms.google-services")

    // END: FlutterFire Configuration

    id("dev.flutter.flutter-gradle-plugin")

}



/**

 * Resolves the Google Maps SDK key for Android manifest placeholders.

 *

 * Precedence:

 * 1. Environment variable VEXDA_ANDROID_MAPS_API_KEY

 * 2. Untracked android/local.properties → VEXDA_ANDROID_MAPS_API_KEY

 * 3. Gradle project property MAPS_API_KEY (-PMAPS_API_KEY=...)

 * 4. Empty string (Maps surfaces will fail until configured)

 */

fun resolveAndroidMapsApiKey(): String {
    val fromEnv = System.getenv("VEXDA_ANDROID_MAPS_API_KEY")?.trim().orEmpty()
    if (fromEnv.isNotEmpty()) {
        return fromEnv
    }

    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        val localProperties = Properties()
        localPropertiesFile.inputStream().use { stream -> localProperties.load(stream) }
        val fromLocal = localProperties.getProperty("VEXDA_ANDROID_MAPS_API_KEY")?.trim().orEmpty()
        if (fromLocal.isNotEmpty()) {
            return fromLocal
        }
    }

    val fromGradle = (project.findProperty("MAPS_API_KEY") as String?)?.trim().orEmpty()
    if (fromGradle.isNotEmpty()) {
        return fromGradle
    }

    return ""
}



val androidMapsApiKey = resolveAndroidMapsApiKey()



if (androidMapsApiKey.isEmpty()) {

    logger.warn(

        """

        |

        |Vexda Maps: VEXDA_ANDROID_MAPS_API_KEY is not configured.

        |Map screens will fail at runtime until you add the key to ONE of:

        |  - environment variable VEXDA_ANDROID_MAPS_API_KEY

        |  - android/local.properties (see local.properties.example)

        |  - Gradle -PMAPS_API_KEY=...

        |See docs/platform/API_KEYS_SETUP.md

        """.trimMargin(),

    )

}



android {

    namespace = "com.vexda.app"

    compileSdk = flutter.compileSdkVersion

    ndkVersion = flutter.ndkVersion



    compileOptions {

        sourceCompatibility = JavaVersion.VERSION_17

        targetCompatibility = JavaVersion.VERSION_17

    }



    kotlin {

        compilerOptions {

            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17

        }

    }



    defaultConfig {

        applicationId = "com.drinkspot.app"

        minSdk = flutter.minSdkVersion

        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode

        versionName = flutter.versionName



        manifestPlaceholders["MAPS_API_KEY"] = androidMapsApiKey

    }



    buildTypes {

        release {

            // TODO: Add your own signing config for the release build.

            // Signing with the debug keys for now, so `flutter run --release` works.

            signingConfig = signingConfigs.getByName("debug")

        }

    }

}



flutter {

    source = "../.."

}


