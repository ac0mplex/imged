const c = @import("c.zig");
const allocator = @import("allocator.zig");
const cli_args = @import("cli_args.zig");
const img = @import("image.zig");
const std = @import("std");

const App = @import("app.zig").App;
const DrawableTexture = @import("view/drawable_texture.zig").DrawableTexture;
const ImageView = @import("view/image_view.zig").ImageView;

pub fn main() anyerror!void {
    const args = cli_args.readAndParse() catch {
        return;
    };

    const image = img.Image.loadFromFile(args.inputFilename) catch {
        std.debug.print("Failed opening {s}\n", .{args.inputFilename});
        return error.InitFailed;
    };
    defer image.unload();

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        c.SDL_Log("Failed to initialize SDL: %s", c.SDL_GetError());
        return error.InitFailed;
    }
    defer c.SDL_Quit();

    const window_title = try std.fmt.allocPrintZ(
        allocator.get(),
        "imged [{s}]",
        .{args.inputFilename},
    );
    defer allocator.get().free(window_title);

    const window = c.SDL_CreateWindow(
        window_title,
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

    const texture = DrawableTexture.fromImage(renderer, image) catch {
        std.debug.print("Failed to create texture\n", .{});
        return error.InitFailed;
    };
    defer texture.unload();

    var app = App{
        .window = window,
        .renderer = renderer,
        .image_view = ImageView.init(texture),
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
            .start = .{
                .x = 0,
                .y = 0,
            },
            .size = .{
                .x = image.getWidth(),
                .y = image.getHeight(),
            },
        },
    };
}
