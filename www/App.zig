const Database = @import("Database.zig");
const sqlite = @import("sqlite");

db: Database,
pkgs_count: *usize,
cdn_url: []const u8,
