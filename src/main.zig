const std = @import("std");

const c = @import("c.zig").imported;
const cli_args = @import("cli_args.zig");
const img = @import("image.zig");
const view = @import("view.zig");

const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool = true,
    image_view: view.ImageView,

    pub fn handleEvents(self: *App) void {
        var event: c.SDL_Event = undefined;
        while (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => self.running = false,
                c.SDL_WINDOWEVENT => switch (event.window.event) {
                    c.SDL_WINDOWEVENT_RESIZED => {
                        self.image_view.updateViewSize(
                            event.window.data1,
                            event.window.data2,
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
        self.image_view.draw(self.renderer);
        _ = c.SDL_RenderPresent(self.renderer);
    }
};

pub fn main() anyerror!void {
    const args = cli_args.readAndParse() catch {
        return;
    };

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

    var renderer = c.SDL_CreateRenderer(window, -1, 0) orelse {
        c.SDL_Log("Failed to create renderer: %s", c.SDL_GetError());
        return error.InitFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const image = img.Image.loadFromFile(args.inputFilename) catch {
        std.debug.warn("Failed opening {}\n", .{args.inputFilename});
        return error.InitFailed;
    };
    defer image.unload();

    const texture = view.DrawableTexture.fromImage(renderer, image) catch {
        std.debug.warn("Failed to create texture\n", .{});
        return error.InitFailed;
    };
    defer texture.unload();

    var app = App{
        .window = window,
        .renderer = renderer,
        .image_view = view.ImageView{
            .image = texture,
        },
    };

    while (app.running) {
        app.handleEvents();
        app.draw();
    }

    if (args.outputFilename) |path| {
        image.saveToFile(path);
    }
}
