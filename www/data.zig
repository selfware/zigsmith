const std = @import("std");
const sqlite = @import("sqlite");

pub fn open(alloc: std.mem.Allocator, path: []const u8) !sqlite.Db {
    const path_c = try alloc.dupeZ(u8, path);
    defer alloc.free(path_c);

    var db = try sqlite.Db.init(.{
        .mode = .{ .File = path_c },
        .open_flags = .{ .write = true, .create = true },
    });
    try db.exec(
        \\CREATE TABLE IF NOT EXISTS builds (
        \\    hash TEXT PRIMARY KEY,
        \\    name TEXT NOT NULL COLLATE NOCASE,
        \\    version TEXT NOT NULL,
        \\    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
        \\);
    , .{}, .{});

    return db;
}

pub fn count(db: *sqlite.Db) !usize {
    const value = try db.one(usize,
        \\SELECT COUNT(*) FROM builds;
    , .{}, .{});

    return value.?;
}

// pub const Package = struct {
//     name: []const u8,
//     versions: []const Version,
// };

// const Version = struct {};
