const builz = @import("builz");
const std = @import("std");

pub fn build(b: *std.Build) !void {
    _ = try builz.format(b.allocator, &.{
        .{
            .exe = "zig",
            .args = &.{ "fmt", "." },
        },
        .{
            .exe = "gofmt",
            .args = &.{ "-l", "-w", "." },
        },
        .{
            .exe = "shfmt",
            .args = &.{ "-i", "2", "-l", "-w", "." },
        },
    }, true);
}
