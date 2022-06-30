# imged

imged is a stupid image editor inspired by viewers like [sxiv](https://github.com/muennich/sxiv) and [vimiv](https://github.com/karlch/vimiv). It is meant to be used from command line to quickly edit the image.

```
Usage: imged INPUT_FILE [OUTPUT_FILE]
```

## Features

* cropping (select cropping area with mouse)
* rotating (r/R keys)

## Compiling

imged has the following dependencies:

* Zig >=0.9.1
* SDL2 >=2.0.22
* FreeImage >=3.18.0

To compile just run `zig build`, look for the binary in `zig-out/bin/`.
