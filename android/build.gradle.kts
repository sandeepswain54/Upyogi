buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add these classpath dependencies:
        classpath("com.android.tools.build:gradle:8.3.2") // Android Gradle Plugin (AGP)  
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.21") // Kotlin version here
        classpath("com.google.gms:google-services:4.4.2") // Google Services (Firebase)
    }
}



plugins {
  
  id("com.google.gms.google-services") version "4.4.2" apply false

}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
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
