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
    rotation: i32 = 0,

    pub fn setRotation(self: *ImageView, rotation: i32) void {
        self.rotation = rotation;
        self.scaleToViewSize();
    }

    pub fn updateViewSize(self: *ImageView, width: i32, height: i32) void {
        self.view_width = @intToFloat(f32, width);
        self.view_height = @intToFloat(f32, height);
        self.scaleToViewSize();
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
            @intToFloat(f32, self.rotation),
            null,
            c.SDL_FLIP_VERTICAL,
        );
    }

    fn scaleToViewSize(self: *ImageView) void {
        const swapDimensions = self.rotation == 90 or self.rotation == 270;

        const actual_width = if (swapDimensions)
            self.image.height
        else
            self.image.width;

        const actual_height = if (swapDimensions)
            self.image.width
        else
            self.image.height;

        self.scale = std.math.min(
            self.view_width / @intToFloat(f32, actual_width),
            self.view_height / @intToFloat(f32, actual_height),
        );
    }
};
