const c = @import("c.zig");
const img = @import("image.zig");

const Cropping = @import("view/cropping.zig").Cropping;
const DrawableTexture = @import("view/drawable_texture.zig").DrawableTexture;
const ImageView = @import("view/image_view.zig").ImageView;
const Vector = @import("util/vector.zig").Vector;

pub const App = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,
    running: bool = true,
    image_view: ImageView,
    transform: img.ImageTransform,
    cropping: Cropping,

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
                        self.cropping.imageViewTransformChanged();
                    },
                    else => {},
                },
                c.SDL_KEYDOWN => switch (event.key.keysym.sym) {
                    c.SDLK_r => {
                        _ = self.cropping.end();
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
                        self.cropping.start(
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
                        if (self.cropping.end()) |cropping_rectangle| {
                            self.transform.cropping_rect = cropping_rectangle;
                        }
                    },
                    else => {},
                },
                c.SDL_MOUSEMOTION => {
                    self.cropping.update(
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
        self.cropping.cropping_rect.draw(self.renderer);
        _ = c.SDL_RenderPresent(self.renderer);
    }

    fn rotateImageClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation + 90, 360);
        self.image_view.setRotation(self.transform.rotation);
        self.cropping.imageViewTransformChanged();
    }

    fn rotateImageAntiClockwise(self: *App) void {
        self.transform.rotation = @rem(self.transform.rotation - 90, 360);
        self.image_view.setRotation(self.transform.rotation);
        self.cropping.imageViewTransformChanged();
    }
};
