const std = @import("std");

var general = std.heap.GeneralPurposeAllocator(.{}){};
var allocator = general.allocator();

pub fn get() *std.mem.Allocator {
    return &allocator;
}
