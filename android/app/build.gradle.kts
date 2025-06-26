// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
//     id("dev.flutter.flutter-gradle-plugin")
//     id("com.google.gms.google-services")
// }

// android {
//     namespace = "com.example.campus_counseling_app"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_11.toString()
//     }

//     defaultConfig {
//         applicationId = "com.example.campus_counseling_app"

//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         release {
//             // TODO: Add your own signing config for the release build.
//             // Signing with the debug keys for now, so `flutter run --release` works.
//             signingConfig = signingConfigs.getByName("debug")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }


// dependencies {
//     implementation platform('com.google.firebase:firebase-bom:33.13.0')
//     implementation("com.google.firebase:firebase-messaging") 

// }








// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     id("dev.flutter.flutter-gradle-plugin")
//     id("com.google.gms.google-services")  // This is correct
// }

// android {
//     namespace = "com.example.campus_counseling_app"
//     compileSdk = flutter.compileSdkVersion
//     ndkVersion = flutter.ndkVersion

//     compileOptions {
//         sourceCompatibility = JavaVersion.VERSION_11
//         targetCompatibility = JavaVersion.VERSION_11
//     }

//     kotlinOptions {
//         jvmTarget = JavaVersion.VERSION_11.toString()
//     }

//     defaultConfig {
//         applicationId = "com.example.campus_counseling_app"
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutter.versionCode
//         versionName = flutter.versionName
//     }

//     buildTypes {
//         release {
//             signingConfig = signingConfigs.getByName("debug")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// dependencies {
//     implementation(platform("com.google.firebase:firebase-bom:33.13.0"))  // Fixed: double quotes and parentheses
//     implementation("com.google.firebase:firebase-messaging")
//     implementation("com.google.firebase:firebase-analytics")  // Add this if you need analytics
// }




plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.campus_counseling_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "26.3.11579264"  // Changed this

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.campus_counseling_app"
        minSdk = 23  // Changed this
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.13.0"))
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")
}