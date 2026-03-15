plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rhemalize.app"
    compileSdk = 36

    sourceSets {
        getByName("main").java.srcDirs("src/main/kotlin")
    }

    defaultConfig {
        applicationId = "com.rhemalize.app"
        // Ensure this is at least 21 if not using multidex, 
        // but adding multidex anyway for compatibility.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"

        // ADDED: Required for many notification/audio libraries
        multiDexEnabled = true
    }

    compileOptions {
        // ADDED: This fixes the 'CheckAarMetadata' failure
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ADDED: The actual library that performs the 'desugaring'
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.3")
}