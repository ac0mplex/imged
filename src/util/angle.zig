const std = @import("std");

pub const Angle = struct {
    radians: f32 = 0,

    pub fn fromRadians(radians: f32) Angle {
        return .{ .radians = radians };
    }

    pub fn fromDegrees(degrees: f32) Angle {
        return .{ .radians = degrees / 180 * std.math.pi };
    }

    pub fn toRadians(self: Angle) f32 {
        return self.radians;
    }

    pub fn toDegrees(self: Angle) f32 {
        return self.radians / std.math.pi * 180;
    }

    pub fn opposite(self: Angle) Angle {
        return .{ .radians = -self.radians };
    }
};
