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

// 1. FORCE COMPILE SDK TO 34 FOR ALL SUBPROJECTS AT CONFIGURATION TIME
subprojects {
    project.plugins.withId("com.android.library") {
        val android = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        android?.compileSdkVersion(34)
    }
}

// 2. MANIFEST NAMESPACE PATCH FOR AGORA IRIS
subprojects {
    tasks.matching {
        it.name.contains("processDebugMainManifest") || it.name.contains("processReleaseMainManifest")
    }.configureEach {
        doFirst {
            val gradleCacheDir = file("${System.getProperty("user.home")}/.gradle/caches")
            if (gradleCacheDir.exists()) {
                gradleCacheDir.walkTopDown()
                    .filter { it.name == "AndroidManifest.xml" && it.path.contains("iris-rtc") }
                    .forEach { manifestFile ->
                        var content = manifestFile.readText()
                        if (content.contains("package=\"io.agora.rtc\"")) {
                            content = content.replace("package=\"io.agora.rtc\"", "package=\"io.agora.rtc.iris\"")
                            manifestFile.writeText(content)
                            println("--> Patched Agora Iris Manifest in: ${manifestFile.path}")
                        }
                    }
            }
        }
    }
}