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

Shader compile
-------
```
./sokol-shdc --input src/shaders/playfield.glsl --output src/shaders/playfield.glsl.zig --slang=glsl410:glsl300es:hlsl5:metal_macos:metal_ios:wgsl --format sokol_zig
```
