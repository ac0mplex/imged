const std = @import("std");

var general = std.heap.GeneralPurposeAllocator(.{}){};

pub fn get() *std.mem.Allocator {
    return &general.allocator;
}
