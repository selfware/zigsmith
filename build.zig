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
            .args = &.{ "-l", "-w", "./www" },
        },
        .{
            .exe = "shfmt",
            .args = &.{ "-i", "2", "-l", "-w", "./scripts" },
        },
        .{
            .exe = "prettier",
            .args = &.{
                "--tab-width",
                "4",
                "-l",
                "-w",
                "./www/static/public",
            },
        },
    }, true);
}
