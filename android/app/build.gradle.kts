import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "com.hadaer_blady.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"


    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.hadaer_blady.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 3
        versionName = "1.0.0"
        multiDexEnabled = true
    }

signingConfigs {
    create("release") {
        storeFile = file("F:/freelancing/hadaer_blady/android/app/hazaerblady-key.jks")
        storePassword = "Ahmed01234"
        keyAlias = "hazaerblady"
        keyPassword = "Ahmed01234"
    }
}

    buildTypes {
        debug {
            isDebuggable = true
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            isDebuggable = false
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
        }
    }

    packaging {
        resources {
            pickFirsts += "**/libc++_shared.so"
            pickFirsts += "**/libjsc.so"
            excludes += "META-INF/DEPENDENCIES"
            excludes += "META-INF/LICENSE"
            excludes += "META-INF/LICENSE.txt"
            excludes += "META-INF/NOTICE"
            excludes += "META-INF/NOTICE.txt"
        }
    }

    lint {
        disable += "InvalidPackage"
        checkReleaseBuilds = false
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.window:window:1.3.0")
    implementation("androidx.window:window-java:1.3.0")
    implementation("androidx.multidex:multidex:2.0.1")

    implementation(platform("com.google.firebase:firebase-bom:32.1.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-analytics")

    implementation("com.google.android.gms:play-services-auth:21.2.0")
    implementation("com.google.android.gms:play-services-base:18.5.0")
    implementation("com.google.android.gms:play-services-location:21.3.0")

    implementation("androidx.work:work-runtime:2.9.1")
    implementation("androidx.lifecycle:lifecycle-process:2.8.7")
}

flutter {
    source = "../.."
}
