const c = @import("../c.zig");
const std = @import("std");

const Angle = @import("../util/angle.zig").Angle;
const DrawableTexture = @import("drawable_texture.zig").DrawableTexture;
const Rectangle = @import("../util/rectangle.zig").Rectangle;
const Transform = @import("transform.zig").Transform;
const Vector = @import("../util/vector.zig").Vector;

pub const ImageView = struct {
    image: DrawableTexture,
    transform: Transform,
    view_size: Vector(i32) = .{},

    pub fn init(image: DrawableTexture) ImageView {
        return .{
            .image = image,
            .transform = .{
                .origin = .{
                    .x = @intToFloat(f64, image.width) / 2,
                    .y = @intToFloat(f64, image.height) / 2,
                },
            },
        };
    }

    pub fn setRotation(self: *ImageView, rotation: i32) void {
        self.transform.rotation = Angle.fromDegrees(@intToFloat(f32, rotation));
        self.resetScale();
    }

    pub fn updateViewSize(self: *ImageView, width: i32, height: i32) void {
        if (width <= 0 or height <= 0) {
            return;
        }

        self.view_size = .{
            .x = width,
            .y = height,
        };

        const view_center = self.view_size.convert(f64).div(2);
        self.transform.offset = view_center.sub(self.transform.origin);

        self.resetScale();
    }

    pub fn calcRectangle(self: ImageView) Rectangle(f64) {
        return self.transform.transform(self.getBaseImageRectangle());
    }

    pub fn draw(self: ImageView, renderer: *c.SDL_Renderer) void {
        const dest_rect = self.calcBaseSDL_Rect();

        _ = c.SDL_RenderCopyEx(
            renderer,
            self.image.texture,
            null,
            &dest_rect,
            self.transform.rotation.toDegrees(),
            null,
            c.SDL_FLIP_VERTICAL,
        );
    }

    fn calcBaseSDL_Rect(self: ImageView) c.SDL_Rect {
        var rect = self.getBaseImageRectangle();

        rect = self.transform.scale(rect);
        rect = self.transform.translate(rect);

        return rect.toSDLRect();
    }

    fn getBaseImageRectangle(self: ImageView) Rectangle(f64) {
        // TODO: maybe move that to image.zig?
        return .{
            .start = .{
                .x = 0,
                .y = 0,
            },
            .size = .{
                .x = @intToFloat(f64, self.image.width),
                .y = @intToFloat(f64, self.image.height),
            },
        };
    }

    fn resetScale(self: *ImageView) void {
        const rotated_image = self.transform.rotate(self.getBaseImageRectangle());

        const view_size_float = self.view_size.convert(f64);
        const scale = std.math.min(
            view_size_float.x / rotated_image.size.x,
            view_size_float.y / rotated_image.size.y,
        );
        self.transform.scaleFactor = .{ .x = scale, .y = scale };
    }
};
