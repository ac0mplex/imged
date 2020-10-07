const allocator = @import("allocator.zig");
const img = @import("image.zig");
const std = @import("std");

pub const Args = struct {
    inputFilename: []const u8,
    outputFilename: ?[]const u8,
};

const ArgsError = error{
    AllocationFailed,
    NoInputFilename,
    TooManyArgs,
    InvalidArg,
};

pub fn readAndParse() ArgsError!Args {
    const args = std.process.argsAlloc(allocator.get()) catch {
        std.debug.print("Failed to allocate memory for arguments.\n", .{});
        return ArgsError.AllocationFailed;
    };

    // TODO: print usage
    if (args.len < 2) {
        std.debug.print("Input filename is required.\n", .{});
        return ArgsError.NoInputFilename;
    }
    if (args.len > 3) {
        std.debug.print("Too many arguments.\n", .{});
        return ArgsError.TooManyArgs;
    }

    var parsedArgs = Args{
        .inputFilename = args[1],
        .outputFilename = if (args.len == 3) args[2] else null,
    };

    if (!validateArgs(parsedArgs)) {
        return ArgsError.InvalidArg;
    }

    return parsedArgs;
}

fn validateArgs(args: Args) bool {
    tryReadFile(args.inputFilename) catch {
        // TODO: different error messages depending on error type?
        std.debug.print("Failed to open file {}\n", .{args.inputFilename});
        return false;
    };

    if (!img.isSupportedRead(args.inputFilename)) {
        std.debug.print("{} is not supported\n", .{args.inputFilename});
        return false;
    }

    if (args.outputFilename) |path| {
        if (!tryWriteFile(path)) {
            // TODO: different error messages depending on error type?
            std.debug.print("Cannot write to file {}\n", .{path});
            return false;
        }

        if (!img.isSupportedWrite(path)) {
            std.debug.print("{} is not supported\n", .{path});
            return false;
        }
    }

    return true;
}

fn tryReadFile(path: []const u8) std.fs.File.OpenError!void {
    if (std.fs.path.isAbsolute(path)) {
        const file = try std.fs.openFileAbsolute(path, .{ .read = true });
        file.close();
    } else {
        const file = try std.fs.cwd().openFile(path, .{ .read = true });
        file.close();
    }
}

fn tryWriteFile(path: []const u8) bool {
    std.os.access(path, std.os.F_OK) catch |err| switch (err) {
        std.os.AccessError.FileNotFound => {
            if (std.fs.path.isAbsolute(path)) {
                const file = std.fs.createFileAbsolute(path, .{}) catch {
                    std.debug.print("can't create file\n", .{});
                    return false;
                };
                file.close();
                std.fs.deleteFileAbsolute(path) catch {
                    std.debug.print("can't delete file\n", .{});
                    return false;
                };
            } else {
                const file = std.fs.cwd().createFile(path, .{}) catch {
                    std.debug.print("can't create file\n", .{});
                    return false;
                };
                file.close();
                std.fs.cwd().deleteFile(path) catch {
                    std.debug.print("can't delete file\n", .{});
                    return false;
                };
            }

            return true;
        },
        else => {
            std.debug.print("some error on access\n", .{});
            return false;
        },
    };

    // We can access file which means it exists - don't overwrite it!
    std.debug.print("file already exists\n", .{});
    return false;
}
