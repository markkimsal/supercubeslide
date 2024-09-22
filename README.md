# Super Cube Slide

Originally developed in 2005, this PyGame old school puzzle game is now available as Free Software.


Screenshots
======
![Dashboard View](http://markkimsal.github.io/ss/supercubeslide.png)

Rewrite in Zig-lang
=====
[Read development blog](https://gist.github.com/markkimsal/0d422071bec4b35907764f6190b76f7b)


Todos:
====

[ ] Cross compile with SDL dlls

[ ] Cross compile on MacOSX


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
