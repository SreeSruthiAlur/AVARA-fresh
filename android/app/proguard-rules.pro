# Flutter & Dart ProGuard / R8 Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Keep native JNI methods (critical for Swiss Ephemeris / Sweph C library FFI)
-keepclasseswithmembernames class * {
    native <methods>;
}

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }

# Preserve enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
