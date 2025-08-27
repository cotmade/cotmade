# Keep all TensorFlow Lite classes
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Explicitly keep GPU delegate and factory classes used via reflection
-keep class org.tensorflow.lite.gpu.** { *; }

# Prevent warnings about missing GPU delegate dependencies (if you don’t use GPU)
-dontwarn org.tensorflow.lite.gpu.**

# Keep JNI interfaces used by GPU
-keep class org.tensorflow.lite.Delegate { *; }

# Keep inner classes
-keepclassmembers class * {
    class *;
}
