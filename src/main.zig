const c = @import("c.zig");
const cli_args = @import("cli_args.zig");
const img = @import("image.zig");
const std = @import("std");

const CroppingRectangle = @import("view/cropping_rectangle.zig").CroppingRectangle;
const CroppingRectangleBuilder = @import("view/cropping_rectangle_builder.zig").CroppingRectangleBuilder;
const DrawableTexture = @import("view/drawable_texture.zig").DrawableTexture;
const ImageView = @import("view/image_view.zig").ImageView;
const Rectangle = @import("util/rectangle.zig").Rectangle;
const Vector = @import("util/vector.zig").Vector;

// TODO: Move app to separate file - let main be only init stuff
const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool = true,
    image_view: ImageView,
    transform: img.ImageTransform,
    cropping_rect: CroppingRectangle = .{},
    cropping_rect_builder: CroppingRectangleBuilder = .{},
    is_editing_crop_rect: bool = false,

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
                        self.cropping_rect_builder.updateTransform(
                            self.image_view.transform,
                        );
                        self.cropping_rect.updateRectangle(
                            self.cropping_rect_builder.calcRectangle(),
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
                c.SDL_MOUSEBUTTONDOWN => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        self.startCropping(
                            Vector(f64).fromSDL_Point(.{
                                .x = event.motion.x,
                                .y = event.motion.y,
                            }),
                        );
                    },
                    else => {},
                },
                c.SDL_MOUSEBUTTONUP => switch (event.button.button) {
                    c.SDL_BUTTON_LEFT => {
                        self.endCropping();
                    },
                    else => {},
                },
                c.SDL_MOUSEMOTION => if (self.is_editing_crop_rect) {
                    self.updateCropping(
                        Vector(f64).fromSDL_Point(.{
                            .x = event.motion.x,
                            .y = event.motion.y,
                        }),
                    );
                },
                else => {},
            }
        }
    }

    pub fn draw(self: *App) void {
        _ = c.SDL_RenderClear(self.renderer);
        self.image_view.draw(self.renderer);
        self.cropping_rect.draw(self.renderer);
        _ = c.SDL_RenderPresent(self.renderer);
    }

    fn rotateImageClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation + 90, 360);
        self.image_view.setRotation(self.transform.rotation);

        if (self.is_editing_crop_rect) {
            self.updateCropping(getMousePosition());
        } else {
            self.cropping_rect_builder.updateTransform(
                self.image_view.transform,
            );
            self.cropping_rect.updateRectangle(
                self.cropping_rect_builder.calcRectangle(),
            );
        }
    }

    fn rotateImageAntiClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation - 90, 360);
        self.image_view.setRotation(self.transform.rotation);

        if (self.is_editing_crop_rect) {
            self.updateCropping(getMousePosition());
        } else {
            self.cropping_rect_builder.updateTransform(
                self.image_view.transform,
            );
            self.cropping_rect.updateRectangle(
                self.cropping_rect_builder.calcRectangle(),
            );
        }
    }

    fn startCropping(self: *App, point: Vector(f64)) void {
        const image_view_rect = self.image_view.calcRectangle();

        if (!image_view_rect.isPointIn(point)) {
            return;
        }

        self.cropping_rect_builder.begin(self.image_view.transform, point);

        self.cropping_rect.show();
        self.updateCropping(point);

        self.is_editing_crop_rect = true;
    }

    fn updateCropping(self: *App, point: Vector(f64)) void {
        const image_view_rect = self.image_view.calcRectangle();

        if (image_view_rect.isPointIn(point)) {
            self.cropping_rect_builder.updateEndPos(point);
        } else {
            var snapped_point = image_view_rect.snapPoint(point);
            self.cropping_rect_builder.updateEndPos(snapped_point);
        }

        self.cropping_rect.updateRectangle(
            self.cropping_rect_builder.calcRectangle(),
        );
    }

    fn endCropping(self: *App) void {
        // TODO: This crashes when called for the first time if user started dragging out of image view
        self.is_editing_crop_rect = false;
        self.transform.cropping_rect = self.cropping_rect_builder.calcImageRectangle();
    }

    fn getMousePosition() Vector(f64) {
        var point: c.SDL_Point = undefined;
        _ = c.SDL_GetMouseState(&point.x, &point.y);
        return Vector(f64).fromSDL_Point(point);
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
