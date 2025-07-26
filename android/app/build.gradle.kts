plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.cotmade.cotmade"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.cotmade.cotmade"
        minSdk = 24
        targetSdk = 35
        versionCode = 23
        versionName = "1.2.4"
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
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
        coreLibraryDesugaringEnabled true  // Enable core library desugaring
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'  // Core desugaring lib
}

