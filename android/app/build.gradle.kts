plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.cotmade.cotmade"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cotmade.cotmade"
        minSdk = 24
        targetSdk = 35
        versionCode = 19
        versionName = "1.0.0"
    }

    signingConfigs {
        create("release") {
            storeFile = file("android/app/cotmade.jks")
            storePassword = "Jennifer321#"
            keyAlias = "Tim"
            keyPassword = "Jennifer321#"
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true
    }

    kotlinOptions {
        jvmTarget = "11"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Required for core library desugaring (Java 8+ APIs)
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.0.4'
}

