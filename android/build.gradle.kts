buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.0") // Latest version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Set the Kotlin version correctly
extra["kotlin_version"] = "1.8.10"

// Fixing build directory handling
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}

// Clean Task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
