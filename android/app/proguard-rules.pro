# just_audio adds this renderer dynamically. Keep its implementation intact in
# release builds; otherwise ExoPlayer can fail before the first audio sample.
-keep class com.ryanheise.just_audio.AudioPlayer$ObserverRenderer { *; }
