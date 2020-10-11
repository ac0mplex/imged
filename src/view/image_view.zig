const c = @import("../c.zig").imported;
const std = @import("std");

const DrawableTexture = @import("drawable_texture.zig").DrawableTexture;

pub const ImageView = struct {
    image: DrawableTexture,
    position_x: f32 = 0,
    position_y: f32 = 0,
    scale: f32 = 1,
    view_width: f32 = 0,
    view_height: f32 = 0,

    pub fn updateViewSize(self: *ImageView, width: i32, height: i32) void {
        self.view_width = @intToFloat(f32, width);
        self.view_height = @intToFloat(f32, height);
        self.scale = std.math.min(
            @intToFloat(f32, width) / @intToFloat(f32, self.image.width),
            @intToFloat(f32, height) / @intToFloat(f32, self.image.height),
        );
    }

    pub fn draw(self: ImageView, renderer: *c.SDL_Renderer) void {
        var dest_rect = self.image.getSDL_Rect();
        dest_rect.x = @floatToInt(c_int, self.view_width / 2.0 + (@intToFloat(f32, dest_rect.x) - self.position_x) * self.scale);
        dest_rect.y = @floatToInt(c_int, self.view_height / 2.0 + (@intToFloat(f32, dest_rect.y) - self.position_y) * self.scale);
        dest_rect.w = @floatToInt(c_int, @intToFloat(f32, dest_rect.w) * self.scale);
        dest_rect.h = @floatToInt(c_int, @intToFloat(f32, dest_rect.h) * self.scale);

        _ = c.SDL_RenderCopyEx(
            renderer,
            self.image.texture,
            null,
            &dest_rect,
            0,
            null,
            @intToEnum(c.SDL_RendererFlip, c.SDL_FLIP_VERTICAL),
        );
    }
};
