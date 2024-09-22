Build for Windoows
==============================

```
zig build -Dtarget=x86_64-windows-gnu
```



Build for Android
==============================
```
zig build --build-file build-android.zig  -Dx86=false -Dandroid=android11 -Dx86_64=false -Darm=false -Dprebuilt-sdl-folder=../jniLibs/arm64/
```
