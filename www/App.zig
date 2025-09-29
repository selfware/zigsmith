const Self = @This();
const data = @import("data.zig");
const sqlite = @import("sqlite");

cdn_url: []const u8,
cache: *Cache,
db: *sqlite.Db,

pub const Cache = struct {
    pkgs: usize,
};
