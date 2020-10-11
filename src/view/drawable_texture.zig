const allocator = @import("../allocator.zig");
const c = @import("../c.zig").imported;
const img = @import("../image.zig");
const std = @import("std");

pub const DrawableTexture = struct {
    texture: *c.SDL_Texture,
    position_x: f32 = 0,
    position_y: f32 = 0,
    width: u32,
    height: u32,

    pub fn fromImage(renderer: *c.SDL_Renderer, image: img.Image) !DrawableTexture {
        const surface = c.SDL_CreateRGBSurfaceFrom(
            image.getBits(),
            @intCast(c_int, image.getWidth()),
            @intCast(c_int, image.getHeight()),
            @intCast(c_int, image.getBPP()),
            @intCast(c_int, image.getPitch()),
            image.getRedMask(),
            image.getGreenMask(),
            image.getBlueMask(),
            if (image.has_alpha) img.getAlphaMask() else 0,
        );
        defer c.SDL_FreeSurface(surface);

        if (image.palette) |image_palette| {
            var palette_colors = allocator.get().alloc(c.SDL_Color, image_palette.size) catch {
                unreachable;
            };
            defer allocator.get().free(palette_colors);

            var i: usize = 0;
            while (i < palette_colors.len) {
                const color = image_palette.getAt(i);
                palette_colors[i].r = color.r;
                palette_colors[i].g = color.g;
                palette_colors[i].b = color.b;
                i += 1;
            }

            var result = c.SDL_SetPaletteColors(
                surface.*.format.*.palette,
                @ptrCast([*c]const c.SDL_Color, palette_colors),
                0,
                @intCast(c_int, palette_colors.len),
            );

            if (result != 0) {
                return error.FailedToSetPaletteColors;
            }
        }

        var texture = c.SDL_CreateTextureFromSurface(renderer, surface) orelse {
            return error.TextureCreationFailed;
        };

        return DrawableTexture{
            .texture = texture,
            .width = @intCast(u32, image.getWidth()),
            .height = @intCast(u32, image.getHeight()),
        };
    }

    pub fn unload(self: DrawableTexture) void {
        c.SDL_DestroyTexture(self.texture);
    }

    pub fn getSDL_Rect(self: DrawableTexture) c.SDL_Rect {
        return c.SDL_Rect{
            .x = @floatToInt(c_int, self.position_x - @intToFloat(f32, self.width / 2)),
            .y = @floatToInt(c_int, self.position_y - @intToFloat(f32, self.height / 2)),
            .w = @intCast(c_int, self.width),
            .h = @intCast(c_int, self.height),
        };
    }
};
