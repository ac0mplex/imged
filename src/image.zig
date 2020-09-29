const c = @import("c.zig").imported;

pub const Image = struct {
    bitmap: *c.FIBITMAP,
    format: c.FREE_IMAGE_FORMAT,

    pub fn loadFromFile(path: [*:0]const u8) !Image {
        const format = c.FreeImage_GetFileType(path, 0);
        const bitmap = c.FreeImage_Load(format, path, 0) orelse return error.ImageOpenError;

        return Image{
            .bitmap = bitmap,
            .format = format,
        };
    }

    pub fn unload(self: Image) void {
        c.FreeImage_Unload(self.bitmap);
    }

    pub fn saveToFile(self: Image, path: [*:0]const u8) void {
        _ = c.FreeImage_Save(self.format, self.bitmap, path, 0);
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
