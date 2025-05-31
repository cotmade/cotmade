// Root-level build.gradle.kts

// Set the Kotlin version globally
extra["kotlin_version"] = "1.8.0"

buildscript {
    repositories {
        // Google's Maven repository
        google()
        // Maven Central repository
        mavenCentral()
    }

    dependencies {
        // Android Gradle Plugin
        classpath("com.android.tools.build:gradle:7.3.0")

        // Kotlin Gradle Plugin
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:${extra["kotlin_version"]}")

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
