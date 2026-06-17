plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Firebase support
}

android {
    namespace = "com.example.church_mobile"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
        languageVersion = "2.1"
        apiVersion = "2.1"
    }

    defaultConfig {
        applicationId = "com.example.church_mobile"
        minSdk = flutter.minSdkVersion  // Required by Firebase Auth
        targetSdk = 36
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
        ndk {
            ndkVersion = "27.2.12479018"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    implementation(platform("com.google.firebase:firebase-bom:32.7.1"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-firestore")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation("com.google.android.gms:play-services-base:18.3.0")
    implementation("com.google.android.gms:play-services-basement:18.3.0")
    implementation("com.google.android.gms:play-services-ads:22.6.0") // Google Mobile Ads
}
