const c = @import("../c.zig");
const std = @import("std");

const Rectangle = @import("../util/rectangle.zig").Rectangle;
const Vector = @import("../util/vector.zig").Vector;
const Transform = @import("transform.zig").Transform;

pub const CroppingRectangleBuilder = struct {
    // TODO: image coordinates instead of screen coordinates to make sure they are preserved between image view transform updates
    // TODO: merge with cropping rectangle?
    start: Vector(f64) = .{},
    end: Vector(f64) = .{},
    image_view_transform: Transform = .{},

    pub fn begin(
        self: *CroppingRectangleBuilder,
        image_view_transform: Transform,
        start_point: Vector(f64),
    ) void {
        self.image_view_transform = image_view_transform;
        self.start = start_point;
        self.end = self.start;
    }

    pub fn updateEndPos(self: *CroppingRectangleBuilder, end_point: Vector(f64)) void {
        self.start = end_point;
    }

    pub fn updateTransform(
        self: *CroppingRectangleBuilder,
        new_transform: Transform,
    ) void {
        const start = self.image_view_transform.inverseTransform(self.start);
        self.start = new_transform.transform(start);

        const end = self.image_view_transform.inverseTransform(self.end);
        self.end = new_transform.transform(end);

        self.image_view_transform = new_transform;
    }

    pub fn calcRectangle(
        self: CroppingRectangleBuilder,
    ) Rectangle(f64) {
        var rectangle = Rectangle(f64).fromTwoPoints(self.start, self.end);

        rectangle = self.image_view_transform.inverseTransform(rectangle);
        rectangle = snapRectangle(rectangle);
        rectangle = self.image_view_transform.transform(rectangle);

        return rectangle;
    }

    pub fn calcImageRectangle(
        self: CroppingRectangleBuilder,
    ) Rectangle(u32) {
        var rectangle = Rectangle(f64).fromTwoPoints(self.start, self.end);

        rectangle = self.image_view_transform.inverseTransform(rectangle);
        rectangle = snapRectangle(rectangle);

        var image_rectangle = Rectangle(u32){
            .start = .{
                .x = @floatToInt(u32, rectangle.start.x),
                .y = @floatToInt(u32, rectangle.start.y),
            },
            .size = .{
                .x = @floatToInt(u32, rectangle.size.x),
                .y = @floatToInt(u32, rectangle.size.y),
            },
        };

        return image_rectangle;
    }

    fn snapRectangle(
        rectangle: Rectangle(f64),
    ) Rectangle(f64) {
        var snapped_rectangle = Rectangle(f64){};

        snapped_rectangle.start.x = @floor(rectangle.start.x);
        snapped_rectangle.start.y = @floor(rectangle.start.y);

        var rectangle_end = rectangle.start.add(rectangle.size);
        rectangle_end.x = @ceil(rectangle_end.x);
        rectangle_end.y = @ceil(rectangle_end.y);
        snapped_rectangle.size = rectangle_end.sub(snapped_rectangle.start);

        return snapped_rectangle;
    }
};
