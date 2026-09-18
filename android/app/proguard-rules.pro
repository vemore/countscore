# CountScore - ProGuard Rules for Release Builds
#
# R8 is enabled for release builds, for the size saving (the app is open source, so
# obfuscation is not the point). android/app/build.gradle.kts sets, in the release build type:
#   isMinifyEnabled = true
#   isShrinkResources = true
#   proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
#
# The keep rules below are what R8 applies on top of the default optimize configuration.
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
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

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

# Release verification is owned by the release-android skill
# (.claude/skills/release-android/SKILL.md, "Verify the artifact"). To exercise these
# rules on a phone, install a release APK — adb cannot install an App Bundle:
#   flutter build apk --release --no-tree-shake-icons
#   adb install -r build/app/outputs/flutter-apk/app-release.apk
# (not over the Play Store install: Play re-signs it, so the signatures differ).
# A class R8 strips shows up in logcat as ClassNotFoundException or NoSuchMethodError: add
# a -keep rule for it, and use -whyareyoukeeping to debug a rule.
#
# ============================================================================
