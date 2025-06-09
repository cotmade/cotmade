// Root-level build.gradle.kts

buildscript {
    // Define the Kotlin version here to make it accessible in the dependencies block
    val kotlin_version = "1.8.0"

    repositories {
        // Google's Maven repository
        google()
        // Maven Central repository
        mavenCentral()
    }

    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:8.4.0")

        // Kotlin Gradle Plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")

        // Google Services Plugin (for Firebase)
        classpath("com.google.gms:google-services:4.3.15")
    }
}

allprojects {
    repositories {
        // Google's Maven repository
        google()
        // Maven Central repository
        mavenCentral()
    }
}

task<Delete>("clean") {
    delete(rootProject.buildDir)
}
