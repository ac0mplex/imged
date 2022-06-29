const std = @import("std");

const Angle = @import("../util/angle.zig").Angle;
const Vector = @import("../util/vector.zig").Vector;
const Rectangle = @import("../util/rectangle.zig").Rectangle;

pub const Transform = struct {
    origin: Vector(f64) = .{},
    offset: Vector(f64) = .{},
    scaleFactor: Vector(f64) = .{},
    rotation: Angle = .{},

    pub fn transform(self: Transform, obj: anytype) @TypeOf(obj) {
        var result = obj;

        result = self.scale(result);
        result = self.rotate(result);
        result = self.translate(result);

        return result;
    }

    pub fn inverseTransform(self: Transform, obj: anytype) @TypeOf(obj) {
        var result = obj;

        var invert = self;
        invert.offset = self.offset.opposite();
        invert.scaleFactor = .{
            .x = 1.0 / self.scaleFactor.x,
            .y = 1.0 / self.scaleFactor.y,
        };
        invert.rotation = self.rotation.opposite();

        result = invert.translate(result);
        result = invert.rotate(result);
        result = invert.scale(result);

        return result;
    }

    pub fn scale(self: Transform, obj: anytype) @TypeOf(obj) {
        const T = @TypeOf(obj);

        if (T == Vector(f64)) {
            var result = obj;

            result = result.sub(self.origin);
            result.x *= self.scaleFactor.x;
            result.y *= self.scaleFactor.y;
            result = result.add(self.origin);

            return result;
        } else if (T == Rectangle(f64)) {
            const p1 = self.scale(obj.start);
            const p2 = self.scale(obj.start.add(obj.size));

            return Rectangle(f64).fromTwoPoints(p1, p2);
        } else {
            @compileError("scale doesn't support this type");
        }
    }

    pub fn rotate(self: Transform, obj: anytype) @TypeOf(obj) {
        const T = @TypeOf(obj);

        if (T == Vector(f64)) {
            var result = obj;

            result = result.sub(self.origin);
            result = result.rotate(self.rotation);
            result = result.add(self.origin);

            return result;
        } else if (T == Rectangle(f64)) {
            const p1 = self.rotate(obj.start);
            const p2 = self.rotate(obj.start.add(obj.size));

            return Rectangle(f64).fromTwoPoints(p1, p2);
        } else {
            @compileError("rotate doesn't support this type");
        }
    }

    pub fn translate(self: Transform, obj: anytype) @TypeOf(obj) {
        const T = @TypeOf(obj);

        if (T == Vector(f64)) {
            return obj.add(self.offset);
        } else if (T == Rectangle(f64)) {
            return Rectangle(f64){
                .start = self.translate(obj.start),
                .size = obj.size,
            };
        } else {
            @compileError("translate doesn't support this type");
        }
    }
};
