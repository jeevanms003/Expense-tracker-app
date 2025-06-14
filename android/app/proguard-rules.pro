# Prevent obfuscation of sqflite classes
-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Add any additional ProGuard rules for other dependencies if needed