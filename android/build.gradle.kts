// allprojects {
//     repositories {
//         google()
//         mavenCentral()
//     }
//     plugins {
//     id("com.android.application")
//     id("com.google.gms.google-services") // <-- ✅ THIS IS REQUIRED
//     kotlin("android")
// }

// }

// buildscript {
//     repositories {
//         google()
//         jcenter()
//     }

// dependencies {
//         classpath ('com.google.gms.google-services:4.4.1')
//         implementation(platform("com.google.firebase:firebase-bom:32.7.0"))
//         implementation("com.google.firebase:firebase-messaging")
//         implementation("com.google.firebase:firebase-analytics")
//     }
// } 

// val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
// rootProject.layout.buildDirectory.value(newBuildDir)

// subprojects {
//     val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//     project.layout.buildDirectory.value(newSubprojectBuildDir)
// }
// subprojects {
//     project.evaluationDependsOn(":app")
// }

// tasks.register<Delete>("clean") {
//     delete(rootProject.layout.buildDirectory)
// }



buildscript {
    repositories {
        google()
        mavenCentral()  // Use mavenCentral() instead of jcenter()
    }

    dependencies {
        classpath("com.google.gms:google-services:4.4.1")  // Fixed: double quotes and parentheses
        // Remove implementation lines - they don't belong in buildscript
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
    // Remove plugins block from here - it doesn't belong in allprojects
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}