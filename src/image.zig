const allocator = @import("allocator.zig");
const c = @import("c.zig").imported;
const std = @import("std");

pub const Image = struct {
    bitmap: *c.FIBITMAP,
    format: c.FREE_IMAGE_FORMAT,
    has_palette: bool,
    has_alpha: bool,
    palette: ?Palette,

    pub fn loadFromFile(path: []const u8) !Image {
        var pathZ = allocator.get().dupeZ(u8, path) catch {
            unreachable;
        };
        defer allocator.get().free(pathZ);

        const format = c.FreeImage_GetFileType(pathZ, 0);
        const bitmap = c.FreeImage_Load(format, pathZ, 0) orelse return error.ImageOpenError;
        //const bitmap2 = c.FreeImage_ConvertTo32Bits(bitmap) orelse return error.ImageOpenError;

        const color_type = c.FreeImage_GetColorType(bitmap);

        var has_alpha: bool = undefined;
        var has_palette: bool = undefined;
        var palette: ?Palette = null;

        switch (color_type) {
            c.FIC_MINISBLACK, c.FIC_MINISWHITE, c.FIC_PALETTE => {
                has_palette = true;
                // TODO: Is alpha really false?
                has_alpha = false;

                palette = Palette{
                    .palette = c.FreeImage_GetPalette(bitmap),
                    .size = c.FreeImage_GetColorsUsed(bitmap),
                };
            },
            c.FIC_RGB => {
                has_palette = false;
                has_alpha = false;
            },
            c.FIC_RGBALPHA => {
                has_palette = false;
                has_alpha = true;
            },
            c.FIC_CMYK => {
                // TODO: Add new error type, change this to CMYKNotSupported or something
                return error.ImageOpenError;
            },
            else => unreachable,
        }

        return Image{
            .bitmap = bitmap,
            .format = format,
            .has_palette = has_palette,
            .has_alpha = has_alpha,
            .palette = palette,
        };
    }

    pub fn unload(self: Image) void {
        c.FreeImage_Unload(self.bitmap);
    }

    pub fn saveToFile(self: Image, path: []const u8) void {
        var pathZ = allocator.get().dupeZ(u8, path) catch {
            unreachable;
        };
        defer allocator.get().free(pathZ);

        var fif = c.FreeImage_GetFIFFromFilename(pathZ);

        _ = c.FreeImage_Save(fif, self.bitmap, pathZ, 0);
    }

    pub fn getWidth(self: Image) c_uint {
        return c.FreeImage_GetWidth(self.bitmap);
    }

    pub fn getHeight(self: Image) c_uint {
        return c.FreeImage_GetHeight(self.bitmap);
    }

    pub fn getBits(self: Image) *u8 {
        return c.FreeImage_GetBits(self.bitmap);
    }

    pub fn getRedMask(self: Image) c_uint {
        return c.FreeImage_GetRedMask(self.bitmap);
    }

    pub fn getBlueMask(self: Image) c_uint {
        return c.FreeImage_GetBlueMask(self.bitmap);
    }

    pub fn getGreenMask(self: Image) c_uint {
        return c.FreeImage_GetGreenMask(self.bitmap);
    }

    pub fn getBPP(self: Image) c_uint {
        return c.FreeImage_GetBPP(self.bitmap);
    }

    pub fn getPitch(self: Image) c_uint {
        return c.FreeImage_GetPitch(self.bitmap);
    }
};

pub const Palette = struct {
    palette: [*]c.RGBQUAD,
    size: usize,

    pub fn getAt(self: Palette, i: usize) Color {
        const rgb_quad = self.palette[0..self.size][i];
        return Color{
            .r = rgb_quad.rgbRed,
            .g = rgb_quad.rgbGreen,
            .b = rgb_quad.rgbBlue,
        };
    }

    pub fn getSize(self: Palette) usize {
        return self.size;
    }
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
};

pub fn isSupportedRead(path: []const u8) bool {
    var pathZ = allocator.get().dupeZ(u8, path) catch {
        unreachable;
    };
    defer allocator.get().free(pathZ);

    var fif = c.FreeImage_GetFileType(pathZ, 0);

    if (fif == c.FIF_UNKNOWN) {
        fif = c.FreeImage_GetFIFFromFilename(pathZ);
    }

    if (fif == c.FIF_UNKNOWN) {
        return false;
    } else {
        return c.FreeImage_FIFSupportsReading(fif) != 0;
    }
}

pub fn isSupportedWrite(path: []const u8) bool {
    var pathZ = allocator.get().dupeZ(u8, path) catch {
        unreachable;
    };
    defer allocator.get().free(pathZ);

    var fif = c.FreeImage_GetFIFFromFilename(pathZ);

    if (fif == c.FIF_UNKNOWN) {
        return false;
    } else {
        return c.FreeImage_FIFSupportsWriting(fif) != 0;
    }
}
