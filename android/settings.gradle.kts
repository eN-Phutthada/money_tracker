pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}

// Automatically patch legacy plugins (such as flutter_tesseract_ocr) that still reference discontinued jcenter()
try {
    val pubCachePath = System.getenv("PUB_CACHE")
    val pubCacheDirs = listOfNotNull(
        pubCachePath?.let { java.io.File(it) },
        java.io.File(System.getProperty("user.home"), "AppData/Local/Pub/Cache"),
        java.io.File(System.getProperty("user.home"), ".pub-cache")
    )
    for (base in pubCacheDirs) {
        val hostedDir = java.io.File(base, "hosted")
        if (hostedDir.exists()) {
            hostedDir.walkTopDown().maxDepth(4).filter {
                it.name == "build.gradle" &&
                it.parentFile?.name == "android" &&
                it.parentFile?.parentFile?.name?.startsWith("flutter_tesseract_ocr") == true
            }.forEach { file ->
                val text = file.readText()
                if (text.contains("jcenter()")) {
                    file.writeText(text.replace("jcenter()", "mavenCentral()"))
                }
            }
        }
    }
} catch (_: Throwable) {}

// Add missing jcenter() method for legacy plugins in Gradle 9+
try {
    val repoHandlerClass = Class.forName("org.gradle.api.artifacts.dsl.RepositoryHandler")
    val defaultRepoHandlerClass = Class.forName("org.gradle.api.internal.artifacts.dsl.DefaultRepositoryHandler")
    val registry = groovy.lang.GroovySystem.getMetaClassRegistry()

    for (clazz in listOf(repoHandlerClass, defaultRepoHandlerClass)) {
        val emc = groovy.lang.ExpandoMetaClass(clazz, false, true)
        emc.registerInstanceMethod("jcenter", object : groovy.lang.Closure<Any>(null) {
            fun doCall(): Any? {
                val handler = delegate as? org.gradle.api.artifacts.dsl.RepositoryHandler
                return handler?.mavenCentral()
            }
            fun doCall(vararg args: Any?): Any? {
                val handler = delegate as? org.gradle.api.artifacts.dsl.RepositoryHandler
                return handler?.mavenCentral()
            }
        })
        emc.initialize()
        registry.setMetaClass(clazz, emc)
    }
} catch (e: Throwable) {
    println("Could not register jcenter shim: $e")
}


include(":app")
