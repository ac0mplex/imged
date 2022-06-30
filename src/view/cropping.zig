const c = @import("../c.zig");
const std = @import("std");

const CroppingRectangle = @import("cropping_rectangle.zig").CroppingRectangle;
const CroppingRectangleBuilder = @import("cropping_rectangle_builder.zig").CroppingRectangleBuilder;
const ImageView = @import("image_view.zig").ImageView;
const Rectangle = @import("../util/rectangle.zig").Rectangle;
const Vector = @import("../util/vector.zig").Vector;

pub const Cropping = struct {
    image_view: *ImageView,
    cropping_rect: CroppingRectangle = .{},
    cropping_rect_builder: CroppingRectangleBuilder,
    is_editing_crop_rect: bool = false,

    pub fn init(
        image_view: *ImageView,
    ) Cropping {
        return .{
            .image_view = image_view,
            .cropping_rect_builder = .{
                .image_size = .{
                    .x = image_view.image.width,
                    .y = image_view.image.height,
                },
            },
        };
    }

    pub fn start(self: *Cropping, point: Vector(f64)) void {
        const image_view_rect = self.image_view.calcRectangle();

        if (!image_view_rect.isPointIn(point)) {
            return;
        }

        self.is_editing_crop_rect = true;

        self.cropping_rect_builder.begin(self.image_view.transform, point);

        self.cropping_rect.show();
        self.update(point);
    }

    pub fn update(self: *Cropping, point: Vector(f64)) void {
        if (!self.is_editing_crop_rect) {
            return;
        }

        const image_view_rect = self.image_view.calcRectangle();

        if (image_view_rect.isPointIn(point)) {
            self.cropping_rect_builder.updateEndPos(point);
        } else {
            var snapped_point = image_view_rect.snapPoint(point);
            self.cropping_rect_builder.updateEndPos(snapped_point);
        }

        self.cropping_rect.updateRectangle(
            self.cropping_rect_builder.calcViewRectangle(),
        );
    }

    pub fn end(self: *Cropping) ?Rectangle(u32) {
        if (!self.is_editing_crop_rect) {
            return null;
        }

        self.is_editing_crop_rect = false;
        return self.cropping_rect_builder.calcImageRectangle();
    }

    pub fn imageViewTransformChanged(self: *Cropping) void {
        if (self.is_editing_crop_rect) {
            self.is_editing_crop_rect = false;
        }

        self.cropping_rect_builder.updateTransform(
            self.image_view.transform,
        );
        self.cropping_rect.updateRectangle(
            self.cropping_rect_builder.calcViewRectangle(),
        );
    }

    fn getMousePosition() Vector(f64) {
        var point: c.SDL_Point = undefined;
        _ = c.SDL_GetMouseState(&point.x, &point.y);
        return Vector(f64).fromSDL_Point(point);
    }
};
