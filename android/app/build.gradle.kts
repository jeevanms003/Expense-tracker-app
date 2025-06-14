plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.expense_tracker"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Required for sqflite_android

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.expense_tracker"
        minSdk = 21 // Compatible with sqflite, suppressed for NDK
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    experimentalProperties["android.ndk.suppressMinSdkVersionError"] = "21" // Suppress NDK minSdk error

    signingConfigs {
        create("release") {
            // TODO: Replace with your actual keystore details for production
            keyAlias = "androiddebugkey" // Temporary for development
            keyPassword = "android"
            storeFile = file("debug.keystore") // Adjust path if needed
            storePassword = "android"
        }
    }

    buildTypes {
        named("release") {
            isMinifyEnabled = true // Correct Kotlin DSL syntax
            isShrinkResources = true // Correct Kotlin DSL syntax
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
        named("debug") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}