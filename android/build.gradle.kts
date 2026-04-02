allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
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

// PERBAIKAN FINAL: Menggunakan Plugin Hooking, bukan afterEvaluate
subprojects {
    // Kode ini akan bereaksi tepat saat library dikenali sebagai Android Library
    plugins.withId("com.android.library") {
        try {
            extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
                if (namespace == null) {
                    namespace = project.group.toString()
                }
            }
        } catch (e: Exception) {
            // Abaikan jika terjadi kesalahan pembacaan ekstensi
        }
    }
}