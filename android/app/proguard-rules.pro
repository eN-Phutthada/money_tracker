# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split & Deferred Components
-dontwarn com.google.android.play.core.**

# Google ML Kit Text Recognition
# Suppress warnings for optional language recognition modules (Chinese, Devanagari, Japanese, Korean)
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep ML Kit text recognition runtime classes
-keep class com.google.mlkit.** { *; }
-keep class com.google_mlkit_text_recognition.** { *; }

# Mobile Scanner
-keep class com.google.zxing.** { *; }
-dontwarn com.google.zxing.**
