const c = @import("c.zig").imported;
const cli_args = @import("cli_args.zig");
const img = @import("image.zig");
const std = @import("std");

const DrawableTexture = @import("view/drawable_texture.zig").DrawableTexture;
const ImageView = @import("view/image_view.zig").ImageView;

const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool = true,
    image_view: ImageView,
    transform: img.ImageTransform,

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
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    c.SDLK_r => {
                        if (event.key.keysym.mod & c.KMOD_SHIFT > 0) {
                            self.rotateImageAntiClockwise();
                        } else {
                            self.rotateImageClockwise();
                        }
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

    fn rotateImageClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation + 90, 360);
        self.image_view.setRotation(self.transform.rotation);
    }

    fn rotateImageAntiClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation - 90, 360);
        self.image_view.setRotation(self.transform.rotation);
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

    const window = c.SDL_CreateWindow(
        "test",
        0,
        0,
        800,
        800,
        c.SDL_WINDOW_RESIZABLE,
    ) orelse {
        c.SDL_Log("Failed to create window: %s", c.SDL_GetError());
        return error.InitFailed;
    };
    defer c.SDL_DestroyWindow(window);

    var renderer = c.SDL_CreateRenderer(
        window,
        -1,
        c.SDL_RENDERER_PRESENTVSYNC,
    ) orelse {
        c.SDL_Log("Failed to create renderer: %s", c.SDL_GetError());
        return error.InitFailed;
    };
    defer c.SDL_DestroyRenderer(renderer);

    const image = img.Image.loadFromFile(args.inputFilename) catch {
        std.debug.print("Failed opening {s}\n", .{args.inputFilename});
        return error.InitFailed;
    };
    defer image.unload();

    const texture = DrawableTexture.fromImage(renderer, image) catch {
        std.debug.print("Failed to create texture\n", .{});
        return error.InitFailed;
    };
    defer texture.unload();

    var app = App{
        .window = window,
        .renderer = renderer,
        .image_view = ImageView{
            .image = texture,
        },
        .transform = getDefaultTransformForImage(image),
    };

    while (app.running) {
        app.handleEvents();
        app.draw();
    }

    if (args.outputFilename) |path| {
        image.saveToFile(
            path,
            app.transform,
        );
    }
}

fn getDefaultTransformForImage(image: img.Image) img.ImageTransform {
    return .{
        .cropping_rect = .{
            .x = 0,
            .y = 0,
            .width = image.getWidth(),
            .height = image.getHeight(),
        },
    };
}
