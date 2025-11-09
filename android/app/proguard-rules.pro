# CountScore - ProGuard Rules for Release Builds
#
# ⚠️ NOTE: ProGuard/R8 is currently DISABLED for CountScore
#
# Since CountScore is an open-source MIT-licensed application, code obfuscation
# provides no security benefit (source code is publicly available on GitHub).
#
# ProGuard/R8 is disabled in android/app/build.gradle.kts:
#   isMinifyEnabled = false
#   isShrinkResources = false
#
# This file is kept for reference if you want to enable shrinking in the future.
#
# Benefits of keeping it disabled:
# - Simpler builds (no configuration issues)
# - Readable crash reports and stack traces
# - Faster build times
# - Easier debugging
#
# To enable ProGuard/R8 in the future:
# 1. Edit android/app/build.gradle.kts
# 2. Set isMinifyEnabled = true and isShrinkResources = true
# 3. Uncomment proguardFiles configuration
# 4. Test thoroughly and fix any issues with these rules
#
# Official Documentation:
# - Flutter: https://docs.flutter.dev/deployment/android#shrinking-your-code-with-r8
# - ProGuard: https://www.guardsquare.com/manual/configuration/usage
# - R8: https://developer.android.com/studio/build/shrink-code

# ============================================================================
# FLUTTER FRAMEWORK
# ============================================================================

# Keep Flutter engine classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Flutter embedding V2
-keep class io.flutter.embedding.** { *; }

# ============================================================================
# KOTLIN
# ============================================================================

# Keep Kotlin metadata
-keep class kotlin.Metadata { *; }

# Keep Kotlin coroutines
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-keepclassmembers class kotlinx.coroutines.** {
    volatile <fields>;
}

# ============================================================================
# GENERAL ANDROID
# ============================================================================

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom views
-keep public class * extends android.view.View {
    public <init>(android.content.Context);
    public <init>(android.content.Context, android.util.AttributeSet);
    public <init>(android.content.Context, android.util.AttributeSet, int);
    public void set*(***);
    *** get*();
}

# Keep Parcelables
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep Serializables
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ============================================================================
# ANNOTATIONS & REFLECTION
# ============================================================================

# Keep annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# ============================================================================
# SPECIFIC PLUGINS (CountScore Dependencies)
# ============================================================================

# SQLite / sqflite
-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }

# Path Provider
-keep class io.flutter.plugins.pathprovider.** { *; }

# Shared Preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# File Picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Wakelock Plus
-keep class com.flutter_webview_plugin.** { *; }

# ============================================================================
# GSON (if used for JSON serialization)
# ============================================================================

# Keep generic signatures for GSON
-keepattributes Signature

# Keep GSON classes
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }

# ============================================================================
# CUSTOM RULES FOR COUNTSCORE
# ============================================================================

# Keep your data model classes if using reflection
# Uncomment and modify if you have model classes that use reflection
# -keep class com.vemore.countscore.models.** { *; }

# If using JSON serialization with code generation
# -keep class **.g.dart { *; }

# ============================================================================
# DEBUGGING
# ============================================================================

# Remove logging in release builds for better performance and security
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}

# ============================================================================
# WARNINGS
# ============================================================================

# Suppress warnings for missing classes (common with multi-platform plugins)
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

# Suppress warnings for Google Play Core (optional Flutter deferred components feature)
# These classes are referenced by Flutter but not used in this app
-dontwarn com.google.android.play.core.**

# ============================================================================
# OPTIMIZATION
# ============================================================================

# Enable aggressive optimization (R8 default, but explicit for clarity)
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-optimizationpasses 5
-allowaccessmodification
-dontpreverify

# ============================================================================
# TESTING
# ============================================================================

# After enabling these rules, always test your release build thoroughly:
# 1. Build release: flutter build appbundle --release
# 2. Install on device: adb install build/app/outputs/bundle/release/app-release.aab
# 3. Test all features, especially:
#    - Database operations (SQLite)
#    - File operations
#    - All app functionality
# 4. Check logs for missing class warnings
#
# If you encounter issues:
# - Check logcat for ProGuard-related errors
# - Add keep rules for affected classes
# - Use -whyareyoukeeping to debug rule issues
#
# ============================================================================
