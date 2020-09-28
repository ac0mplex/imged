const c = @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("FreeImage.h");
});
const std = @import("std");

const Image = struct {
    bitmap: *c.FIBITMAP,
    format: c.FREE_IMAGE_FORMAT,
};

fn loadImage(path: [*:0]const u8) !Image {
    const format = c.FreeImage_GetFileType(path, 0);
    const bitmap = c.FreeImage_Load(format, path, 0) orelse return error.ImageOpenError;

    return Image{
        .bitmap = bitmap,
        .format = format,
    };
}

fn createTextureFromBitmap(renderer: *c.SDL_Renderer, bitmap: *c.FIBITMAP) !?*c.SDL_Texture {
    const surface = c.SDL_CreateRGBSurfaceFrom(
        c.FreeImage_GetBits(bitmap),
        @intCast(c_int, c.FreeImage_GetWidth(bitmap)),
        @intCast(c_int, c.FreeImage_GetHeight(bitmap)),
        @intCast(c_int, c.FreeImage_GetBPP(bitmap)),
        @intCast(c_int, c.FreeImage_GetPitch(bitmap)),
        c.FreeImage_GetRedMask(bitmap),
        c.FreeImage_GetGreenMask(bitmap),
        c.FreeImage_GetBlueMask(bitmap),
        0x000000ff,
    );
    defer c.SDL_FreeSurface(surface);

    return c.SDL_CreateTextureFromSurface(renderer, surface) orelse error.TextureCreationFailed;
}

pub fn main() anyerror!void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Failed to initialize SDL: %s", c.SDL_GetError());
        return;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("test", 0, 0, 800, 800, c.SDL_WINDOW_RESIZABLE) orelse {
        c.SDL_Log("Failed to create window: %s", c.SDL_GetError());
        return;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
        c.SDL_Log("Failed to create renderer: %s", c.SDL_GetError());
        return;
    };
    defer c.SDL_DestroyRenderer(renderer);

    // This is not needed when using FreeImage as a .SO
    // c.FreeImage_Initialise(0);
    // defer c.FreeImage_DeInitialise();

    const path = "zig-cache/bin/test.jpg";
    const image = loadImage(path) catch {
        std.debug.warn("Failed opening {}\n", .{path});
        return;
    };
    defer c.FreeImage_Unload(image.bitmap);

    const texture = createTextureFromBitmap(renderer, image.bitmap) catch {
        std.debug.warn("Failed to create texture\n", .{});
        return;
    };
    defer c.SDL_DestroyTexture(texture);

    var open = true;
    while (open) {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => {
                    open = false;
                },
                c.SDL_WINDOWEVENT => {
                    switch (event.window.event) {
                        c.SDL_WINDOWEVENT_RESIZED => {
                            std.debug.warn(
                                "Window {} resized to {}x{}\n",
                                .{ event.window.windowID, event.window.data1, event.window.data2 },
                            );
                        },
                        else => {},
                    }
                },
                else => {},
            }
        }

        _ = c.SDL_RenderClear(renderer);
        _ = c.SDL_RenderCopyEx(renderer, texture, null, null, 0, null, @intToEnum(c.SDL_RendererFlip, c.SDL_FLIP_VERTICAL));
        _ = c.SDL_RenderPresent(renderer);
    }

    _ = c.FreeImage_Save(image.format, image.bitmap, "output_image", 0);
}
