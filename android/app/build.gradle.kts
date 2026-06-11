plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.diabete_app1"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17

        // Hada hwa l-hal dyal l-khet'a dyal flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }


    defaultConfig {
        applicationId = "com.example.diabete_app1"
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Zidi had l-kht bach t-t-fada khet'at akhra d-MultiDex
        multiDexEnabled = true
    }
    // ...
}

dependencies {
    // HAD HWA L-HAL: Zidi had l-khet hna
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}