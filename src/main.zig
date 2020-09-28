const c = @cImport({
    @cInclude("SDL2/SDL.h");
});
const std = @import("std");

const img = @import("image.zig");
const Image = img.Image;

fn createTextureFromBitmap(renderer: *c.SDL_Renderer, image: Image) !*c.SDL_Texture {
    const surface = c.SDL_CreateRGBSurfaceFrom(
        image.getBits(),
        @intCast(c_int, image.getWidth()),
        @intCast(c_int, image.getHeight()),
        @intCast(c_int, image.getBPP()),
        @intCast(c_int, image.getPitch()),
        image.getRedMask(),
        image.getGreenMask(),
        image.getBlueMask(),
        0x000000ff,
    );
    defer c.SDL_FreeSurface(surface);

    return c.SDL_CreateTextureFromSurface(renderer, surface) orelse error.TextureCreationFailed;
}

const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool = true,
    image: Image,
    texture: *c.SDL_Texture,

    pub fn saveImage(self: *App) void {
        img.saveImage(self.image, "output_image");
    }

    pub fn handleEvents(self: *App) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => self.running = false,
                c.SDL_WINDOWEVENT => switch (event.window.event) {
                    c.SDL_WINDOWEVENT_RESIZED => {
                        std.debug.warn(
                            "Window {} resized to {}x{}\n",
                            .{ event.window.windowID, event.window.data1, event.window.data2 },
                        );
                    },
                    else => {},
                },
                else => {},
            }
        }
    }

    pub fn draw(self: *App) void {
        _ = c.SDL_RenderClear(self.renderer);
        _ = c.SDL_RenderCopyEx(self.renderer, self.texture, null, null, 0, null, @intToEnum(c.SDL_RendererFlip, c.SDL_FLIP_VERTICAL));
        _ = c.SDL_RenderPresent(self.renderer);
    }
};

pub fn main() anyerror!void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Failed to initialize SDL: %s", c.SDL_GetError());
        return error.InitFailed;
    }
    defer c.SDL_Quit();

    const window = c.SDL_CreateWindow("test", 0, 0, 800, 800, c.SDL_WINDOW_RESIZABLE) orelse {
        c.SDL_Log("Failed to create window: %s", c.SDL_GetError());
        return error.InitFailed;
    };
    defer c.SDL_DestroyWindow(window);

    const renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
        c.SDL_Log("Failed to create renderer: %s", c.SDL_GetError());
        return error.InitFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const path = "zig-cache/bin/test.jpg";
    const image = img.loadImage(path) catch {
        std.debug.warn("Failed opening {}\n", .{path});
        return error.InitFailed;
    };
    defer image.unload();

    const texture = createTextureFromBitmap(renderer, image) catch {
        std.debug.warn("Failed to create texture\n", .{});
        return error.InitFailed;
    };
    defer c.SDL_DestroyTexture(texture);

    var app = App{
        .window = window,
        .renderer = renderer,
        .image = image,
        .texture = texture,
    };

    while (app.running) {
        app.handleEvents();
        app.draw();
    }

    app.saveImage();
}
