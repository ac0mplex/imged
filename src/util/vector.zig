const c = @import("../c.zig");
const std = @import("std");

const Angle = @import("angle.zig").Angle;

pub fn Vector(comptime T: type) type {
    switch (@typeInfo(T)) {
        .Int, .Float => {},
        else => throwNotSupportedTypeError(T),
    }

    return struct {
        const Self = @This();

        x: T = 0,
        y: T = 0,

        pub fn fromSDL_Point(point: c.SDL_Point) Self {
            return switch (@typeInfo(T)) {
                .Int => .{
                    .x = @intCast(T, point.x),
                    .y = @intCast(T, point.y),
                },
                .Float => .{
                    .x = @intToFloat(T, point.x),
                    .y = @intToFloat(T, point.y),
                },
                else => throwNotSupportedTypeError(T),
            };
        }

        pub fn convert(self: Self, comptime OtherT: type) Vector(OtherT) {
            return switch (@typeInfo(OtherT)) {
                .Int => switch (@typeInfo(T)) {
                    .Int => .{
                        .x = @intCast(OtherT, self.x),
                        .y = @intCast(OtherT, self.y),
                    },
                    .Float => .{
                        .x = @floatToInt(OtherT, self.x),
                        .y = @floatToInt(OtherT, self.y),
                    },
                    else => throwNotSupportedTypeError(T),
                },
                .Float => switch (@typeInfo(T)) {
                    .Int => .{
                        .x = @intToFloat(OtherT, self.x),
                        .y = @intToFloat(OtherT, self.y),
                    },
                    .Float => .{
                        .x = @floatCast(OtherT, self.x),
                        .y = @floatCast(OtherT, self.y),
                    },
                    else => throwNotSupportedTypeError(T),
                },
                else => throwNotSupportedTypeError(OtherT),
            };
        }

        pub fn add(self: Self, other: Self) Self {
            return .{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }

        pub fn sub(self: Self, other: Self) Self {
            return .{
                .x = self.x - other.x,
                .y = self.y - other.y,
            };
        }

        pub fn mul(self: Self, a: T) Self {
            return .{
                .x = self.x * a,
                .y = self.y * a,
            };
        }

        pub fn div(self: Self, a: T) Self {
            return .{
                .x = self.x / a,
                .y = self.y / a,
            };
        }

        pub fn opposite(self: Self) Self {
            return .{
                .x = -self.x,
                .y = -self.y,
            };
        }

        pub fn rotate(self: Self, angle: Angle) Self {
            const radians = angle.toRadians();
            const x = self.x * std.math.cos(radians) - self.y * std.math.sin(radians);
            const y = self.x * std.math.sin(radians) + self.y * std.math.cos(radians);

            return .{
                .x = x,
                .y = y,
            };
        }
    };
}

fn throwNotSupportedTypeError(comptime T: type) void {
    @compileError(
        std.fmt.format("Vector doesn't support {}", .{@typeName(T)}),
    );
}
