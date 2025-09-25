const Self = @This();
const std = @import("std");
const sqlite = @import("sqlite");

db: *sqlite.Db,

pub fn open(alloc: std.mem.Allocator, path: []const u8) !Self {
    const path_c = try alloc.dupeZ(u8, path);

    var db = try sqlite.Db.init(.{
        .open_flags = .{ .write = true, .create = true },
        .mode = .{ .File = path_c },
    });

    return .{ .db = &db };
}

pub const Package = struct {
    name: []const u8,
    versions: []const Version,
};

const Version = struct {};
