const c = @import("../c.zig");
const std = @import("std");

const Rectangle = @import("../util/rectangle.zig").Rectangle;

pub const CroppingRectangle = struct {
    rectangle: Rectangle(f64) = .{},
    shown: bool = false,

    pub fn show(self: *CroppingRectangle) void {
        self.shown = true;
    }

    pub fn hide(self: *CroppingRectangle) void {
        self.shown = false;
    }

    pub fn updateRectangle(self: *CroppingRectangle, rectangle: Rectangle(f64)) void {
        self.rectangle = rectangle;
    }

    pub fn draw(self: CroppingRectangle, renderer: *c.SDL_Renderer) void {
        if (!self.shown) return;

        self.drawOutline(renderer, -2, 2, .{ .r = 0, .g = 0, .b = 0, .a = 255 });
        self.drawOutline(renderer, 0, 2, .{ .r = 255, .g = 255, .b = 255, .a = 255 });
        self.drawOutline(renderer, 2, 2, .{ .r = 0, .g = 0, .b = 0, .a = 255 });
    }

    fn drawOutline(
        self: CroppingRectangle,
        renderer: *c.SDL_Renderer,
        dist: i32,
        thickness: i32,
        color: c.SDL_Color,
    ) void {
        const self_rect = self.rectangle.toSDLRect();
        const rects = [_]c.SDL_Rect{
            .{ // Top
                .x = self_rect.x - dist - thickness,
                .y = self_rect.y - dist - thickness,
                .w = self_rect.w + 2 * dist + 2 * thickness,
                .h = thickness,
            },
            .{ // Left
                .x = self_rect.x - dist - thickness,
                .y = self_rect.y - dist - thickness,
                .w = thickness,
                .h = self_rect.h + 2 * dist + 2 * thickness,
            },
            .{ // Bottom
                .x = self_rect.x - dist - thickness,
                .y = self_rect.y + self_rect.h + dist,
                .w = self_rect.w + 2 * dist + 2 * thickness,
                .h = thickness,
            },
            .{ // Right
                .x = self_rect.x + self_rect.w + dist,
                .y = self_rect.y - dist - thickness,
                .w = thickness,
                .h = self_rect.h + 2 * dist + 2 * thickness,
            },
        };

        _ = c.SDL_SetRenderDrawColor(
            renderer,
            color.r,
            color.g,
            color.b,
            color.a,
        );
        _ = c.SDL_RenderFillRects(
            renderer,
            &rects,
            rects.len,
        );
    }
};
