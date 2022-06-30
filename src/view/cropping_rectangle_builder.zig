const c = @import("../c.zig");
const std = @import("std");

const Rectangle = @import("../util/rectangle.zig").Rectangle;
const Vector = @import("../util/vector.zig").Vector;
const Transform = @import("transform.zig").Transform;

pub const CroppingRectangleBuilder = struct {
    start: Vector(f64) = .{},
    end: Vector(f64) = .{},
    last_image_rectangle: ?Rectangle(u32) = null,
    image_size: Vector(u32),
    image_view_transform: Transform = .{},

    pub fn init(image_size: Vector(u32)) CroppingRectangleBuilder {
        return .{ .image_size = image_size };
    }

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
        self.end = end_point;
    }

    pub fn updateTransform(
        self: *CroppingRectangleBuilder,
        new_transform: Transform,
    ) void {
        if (self.last_image_rectangle) |last_image_rectangle| {
            // Offset by 0.5 so that we're at the center of the pixel.
            // This way we can avoid floating point precission errors.
            const offset = Vector(f64){ .x = 0.5, .y = 0.5 };

            const start = last_image_rectangle.start.convert(f64).add(offset);
            self.start = new_transform.transform(start);

            const orig_end = last_image_rectangle.start.add(last_image_rectangle.size);
            const end = orig_end.convert(f64).sub(offset);
            self.end = new_transform.transform(end);
        }

        self.image_view_transform = new_transform;
    }

    pub fn calcViewRectangle(
        self: *CroppingRectangleBuilder,
    ) Rectangle(f64) {
        var rectangle = Rectangle(f64).fromTwoPoints(self.start, self.end);

        rectangle = self.image_view_transform.inverseTransform(rectangle);
        rectangle = self.snapRectangle(rectangle);
        rectangle = self.image_view_transform.transform(rectangle);

        return rectangle;
    }

    pub fn calcImageRectangle(
        self: *CroppingRectangleBuilder,
    ) Rectangle(u32) {
        var rectangle = Rectangle(f64).fromTwoPoints(self.start, self.end);

        rectangle = self.image_view_transform.inverseTransform(rectangle);
        rectangle = self.snapRectangle(rectangle);

        self.last_image_rectangle = Rectangle(u32){
            .start = .{
                .x = @floatToInt(u32, rectangle.start.x),
                .y = @floatToInt(u32, rectangle.start.y),
            },
            .size = .{
                .x = @floatToInt(u32, rectangle.size.x),
                .y = @floatToInt(u32, rectangle.size.y),
            },
        };

        return self.last_image_rectangle.?;
    }

    fn snapRectangle(
        self: CroppingRectangleBuilder,
        rectangle: Rectangle(f64),
    ) Rectangle(f64) {
        var snapped_rectangle = Rectangle(f64){};

        snapped_rectangle.start.x = std.math.max(0, @floor(rectangle.start.x));
        snapped_rectangle.start.y = std.math.max(0, @floor(rectangle.start.y));

        var rectangle_end = rectangle.start.add(rectangle.size);
        rectangle_end.x = std.math.min(
            @intToFloat(f64, self.image_size.x),
            @ceil(rectangle_end.x),
        );
        rectangle_end.y = std.math.min(
            @intToFloat(f64, self.image_size.y),
            @ceil(rectangle_end.y),
        );
        snapped_rectangle.size = rectangle_end.sub(snapped_rectangle.start);

        return snapped_rectangle;
    }
};
