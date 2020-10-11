const allocator = @import("allocator.zig");
const c = @import("c.zig").imported;
const std = @import("std");

// TODO: Test more file formats for reading
const FIFs_supporting_read = [_]c.FREE_IMAGE_FORMAT{
    c.FIF_JPEG,
    c.FIF_PNG,
    c.FIF_GIF,
};

// TODO: Test more file formats for writing
const FIFs_supporting_write = [_]c.FREE_IMAGE_FORMAT{
    c.FIF_JPEG,
    c.FIF_PNG,
    c.FIF_GIF,
};

pub const Image = struct {
    bitmap: *c.FIBITMAP,
    format: c.FREE_IMAGE_FORMAT,
    has_alpha: bool,
    palette: ?Palette,

    pub fn loadFromFile(path: []const u8) !Image {
        var pathZ = allocator.get().dupeZ(u8, path) catch {
            unreachable;
        };
        defer allocator.get().free(pathZ);

        const format = c.FreeImage_GetFileType(pathZ, 0);
        const bitmap = c.FreeImage_Load(format, pathZ, 0) orelse return error.ImageOpenError;

        const color_type = c.FreeImage_GetColorType(bitmap);

        var has_alpha: bool = undefined;
        var palette: ?Palette = null;

        switch (color_type) {
            c.FIC_MINISBLACK, c.FIC_MINISWHITE, c.FIC_PALETTE => {
                has_alpha = false;

                palette = Palette{
                    .palette = c.FreeImage_GetPalette(bitmap),
                    .size = c.FreeImage_GetColorsUsed(bitmap),
                };
            },
            c.FIC_RGB => {
                has_alpha = false;
            },
            c.FIC_RGBALPHA => {
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

        const fif = c.FreeImage_GetFIFFromFilename(pathZ);
        const bpp = c.FreeImage_GetBPP(self.bitmap);

        var cloned_bitmap: [*c]c.FIBITMAP = undefined;

        switch (fif) {
            c.FIF_JPEG => {
                if (bpp != 24) {
                    cloned_bitmap = c.FreeImage_ConvertTo24Bits(self.bitmap);
                } else {
                    cloned_bitmap = self.bitmap;
                }
            },
            c.FIF_PNG => {
                if (bpp != 32) {
                    cloned_bitmap = c.FreeImage_ConvertTo32Bits(self.bitmap);
                } else {
                    cloned_bitmap = self.bitmap;
                }
            },
            c.FIF_GIF => {
                if (bpp == 24 or bpp == 32) {
                    cloned_bitmap = c.FreeImage_ColorQuantize(self.bitmap, c.FIQ_WUQUANT);
                } else {
                    cloned_bitmap = self.bitmap;
                }
            },
            else => @panic("Saving to this filetype is not supported"),
        }

        _ = c.FreeImage_Save(fif, cloned_bitmap, pathZ, 0);

        if (cloned_bitmap != self.bitmap) {
            c.FreeImage_Unload(cloned_bitmap);
        }
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
        const rgb_quad = self.palette[i];

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

pub fn getAlphaMask() u32 {
    return c.FI_RGBA_ALPHA_MASK;
}

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
        var supported_read = false;

        for (FIFs_supporting_read) |supported_fif| {
            if (supported_fif == fif) supported_read = true;
        }

        return supported_read and c.FreeImage_FIFSupportsReading(fif) != 0;
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
        var supported_write = false;

        for (FIFs_supporting_write) |supported_fif| {
            if (supported_fif == fif) supported_write = true;
        }

        return supported_write and c.FreeImage_FIFSupportsWriting(fif) != 0;
    }
}
