const c = @import("../c.zig");
const std = @import("std");

const Vector = @import("vector.zig").Vector;

pub fn Rectangle(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Int, .Float => {},
        else => throwNotSupportedTypeError(T),
    }

    return struct {
        const Self = @This();

        start: Vector(T) = .{},
        size: Vector(T) = .{},

        pub fn fromSDLRect(sdl_rect: c.SDL_Rect) Self {
            return switch (@typeInfo(T)) {
                .Int => .{
                    .start = .{
                        .x = @intCast(T, sdl_rect.x),
                        .y = @intCast(T, sdl_rect.y),
                    },
                    .size = .{
                        .x = @intCast(T, sdl_rect.w),
                        .y = @intCast(T, sdl_rect.h),
                    },
                },
                .Float => .{
                    .start = .{
                        .x = @intToFloat(T, sdl_rect.x),
                        .y = @intToFloat(T, sdl_rect.y),
                    },
                    .size = .{
                        .x = @intToFloat(T, sdl_rect.w),
                        .y = @intToFloat(T, sdl_rect.h),
                    },
                },
                else => throwNotSupportedTypeError(T),
            };
        }

        pub fn fromStartEndPoints(start: Vector(T), end: Vector(T)) Self {
            return .{
                .start = start,
                .size = end.sub(start),
            };
        }

        pub fn fromTwoPoints(p1: Vector(T), p2: Vector(T)) Self {
            const start: Vector(T) = .{
                .x = std.math.min(p1.x, p2.x),
                .y = std.math.min(p1.y, p2.y),
            };
            const size: Vector(T) = .{
                .x = std.math.max(p1.x, p2.x) - start.x,
                .y = std.math.max(p1.y, p2.y) - start.y,
            };
            return .{
                .start = start,
                .size = size,
            };
        }

        pub fn toSDLRect(self: Self) c.SDL_Rect {
            return switch (@typeInfo(T)) {
                .Int => .{
                    .x = @intCast(c_int, self.start.x),
                    .y = @intCast(c_int, self.start.y),
                    .w = @intCast(c_int, self.size.x),
                    .h = @intCast(c_int, self.size.y),
                },
                .Float => .{
                    .x = @floatToInt(c_int, self.start.x),
                    .y = @floatToInt(c_int, self.start.y),
                    .w = @floatToInt(c_int, self.size.x),
                    .h = @floatToInt(c_int, self.size.y),
                },
                else => throwNotSupportedTypeError(T),
            };
        }

        pub fn snapPoint(self: Self, point: Vector(T)) Vector(T) {
            var snapped_point = point;

            if (point.x > self.start.x + self.size.x) {
                snapped_point.x = self.start.x + self.size.x;
            } else if (point.x < self.start.x) {
                snapped_point.x = self.start.x;
            }

            if (point.y > self.start.y + self.size.y) {
                snapped_point.y = self.start.y + self.size.y;
            } else if (point.y < self.start.y) {
                snapped_point.y = self.start.y;
            }

            return snapped_point;
        }

        pub fn isPointIn(self: Self, point: Vector(T)) bool {
            return point.x >= self.start.x and
                point.x <= self.start.x + self.size.x and
                point.y >= self.start.y and
                point.y <= self.start.y + self.size.y;
        }
    };
}

fn throwNotSupportedTypeError(comptime T: type) void {
    @compileError(
        std.fmt.format("Rectangle doesn't support {}", .{@typeName(T)}),
    );
}
